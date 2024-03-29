---
title: "Testing IAM permissions in Terraform"
date: 2024-03-29 20:30:00 +0000
---

[mod]: https://github.com/george-richardson/terraform-aws-state-access-role
[mod_tests]: https://github.com/george-richardson/terraform-aws-state-access-role/blob/main/tests/simple_apply.tftest.hcl
[pol_sim]: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_principal_policy_simulation
[tf_test]: https://developer.hashicorp.com/terraform/language/tests

I have recently been writing [a Terraform module for least privilege access to centralised Terraform state and locking in AWS][mod]. Although its not the most complicated module in the world, I did want to be sure that it was generating least privilege IAM policies, and will continue to do so in the future. It turns out the [Terraform `test` command][tf_test], combined with the [`iam_principal_policy_simulation` data source][pol_sim], makes it suprisingly easy to unit test your permissions policies. 

![A painting of a hard hat on a scale.](/hard-hat-on-scale.jpg)

Let's test a simple IAM role which we will grant the ability to download any objects from an S3 bucket that are prefixed with "accessible/". We can define the role and bucket in a root module like this:

```terraform
# main.tf

variable "bucket_name" {}
variable "role_name" {}

data "aws_caller_identity" "current" {}

# Our role we are going to test
resource "aws_iam_role" "role" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.trust.json
  inline_policy {
    name   = "get-s3"
    policy = data.aws_iam_policy_document.s3_get_object.json
  }
}

# The permissions policy we are going to test
data "aws_iam_policy_document" "s3_get_object" {
  statement {
    effect    = "Allow"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.objects.arn}/accessible/*"]
  }
}

data "aws_iam_policy_document" "trust" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [data.aws_caller_identity.current.arn]
    }
  }
}

resource "aws_s3_bucket" "objects" {
  bucket = var.bucket_name
}

# Outputs for wiring up the tests
output "role_arn" {
  value = aws_iam_role.role.arn
}

output "bucket_arn" {
  value = aws_s3_bucket.objects.arn
}


```

Now let's create a test helper module that contains the `aws_iam_principal_policy_simulation` data source which we can call from our test files. 

```terraform
# tests/policy_simulation/main.tf

# These variables will just get passed straight through to the 
# aws_iam_principal_policy_simulation data source. If you need to configure
# other arguments of the simulation, you can add more variables.
variable "action_names" {
  type = list(string)
}

variable "policy_source_arn" {
  type = string
}

variable "resource_arns" {
  type = list(string)
}

# Here's where the magic happens!
data "aws_iam_principal_policy_simulation" "test" {
  action_names      = var.action_names
  policy_source_arn = var.policy_source_arn
  resource_arns     = var.resource_arns
}

# Output all attributes of the simulation for access in our test file.
output "test_results" {
  value = data.aws_iam_principal_policy_simulation.test
}

```

Finally we can write some tests. One test will check we can get an object with the correct prefix, another will ensure we cannot get an object with an incorrect prefix.

```hcl
# tests/role_test.tftest.hcl
run "system_under_test" {
  variables {
    role_name   = "test-role"
    bucket_name = "iam-test-example-bucket"
  }
}

run "can_get_prefixed_object" {
  # Use our helper module
  module {
    source = "./tests/policy_simulation"
  }

  variables {
    action_names      = ["s3:GetObject"]
    policy_source_arn = run.system_under_test.role_arn
    resource_arns     = ["${run.system_under_test.bucket_arn}/accessible/file"]
  }

  assert {
    # all_allowed is an attribute of aws_iam_principal_policy_simulation
    condition     = output.test_results.all_allowed
    error_message = "Cannot get object 'accessible/file'."
  }
}

run "cannot_get_unprefixed_object" {
  module {
    source = "./tests/policy_simulation"
  }

  variables {
    action_names      = ["s3:GetObject"]
    policy_source_arn = run.system_under_test.role_arn
    resource_arns     = ["${run.system_under_test.bucket_arn}/wrongprefix/file"]
  }

  assert {
    condition     = !output.test_results.all_allowed
    error_message = "Can get object 'wrongprefix/file'."
  }
}
```

At this point we can run `terraform test` and validate our role is functioning as intended:

```console
> terraform test
tests/role_test.tftest.hcl... in progress
  run "system_under_test"... pass
  run "can_get_prefixed_object"... pass
  run "cannot_get_unprefixed_object"... pass
tests/role_test.tftest.hcl... tearing down
tests/role_test.tftest.hcl... pass

Success! 3 passed, 0 failed.
```

Now is this useful? In this simplictic example, probably not! However, if you are using complex logic to generate your IAM policies, this can be a great way to ensure they are working as expected.

You can see more complete examples in my module's [tests directory][mod_tests].
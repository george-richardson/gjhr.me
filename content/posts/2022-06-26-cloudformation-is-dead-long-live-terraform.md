---
title: "CloudFormation is Dead, Long Live Terraform"
date: 2022-06-26 08:00:00 +0000
---

If CloudFormation were a person, it would be just starting secondary school, worrying about looking cool to its new friends, yet not old enough to drink or drive. If CloudFormation were a dog it would be enjoying its twilight years, lying in bed, chasing squirrels out of habit with no expectation of catching them. Unfortunately, CloudFormation is software... neglected software. CloudFormation is a draugr, a zombie, a lich. CloudFormation should have a stake thrust through its heart and its brain stem destroyed before being buried in a uranium box at the bottom of the deepest ocean.

![A robot skeleton silently screams](/technolich.jpg "Found inside a server rack in us-east-1.")

The lich that is CloudFormation was once a comely prince. In 2010, it offered a fresh perspective on cloud infrastructure. You could now define your resources declaratively, no more keeping track of hundreds of manually created resources across all the different AWS services. Now you can put them all in a text file and have a centralised place to configure and manage them. Brilliant! But the honeymoon period is over, other tools have come along that have improved on the concept. If CloudFormation was King, it’s looking like Terraform will be our Robespierre.   

## CloudFormation Can’t Keep Up

There is nothing more aggravating than finding out a crucial AWS resource does not have its own native CloudFormation definition. AWS Organizations was released as a preview service in 2016, by mid-2017 the Terraform AWS provider had a bare-bones implementation of the resource. 5 years later, it is now 2022 and CloudFormation still doesn’t support AWS Organizations resources. 

Slightly less annoying, but altogether more frequent, is that a new feature for an existing service isn’t supported. It’s pretty counterintuitive that the first party IaC tool lags behind a third-party effort here. Recently, [SQS added support for managed encryption at rest][a1]. It took [17 days][a2] for this new feature to get released in Terraform. As of writing, it has been 214 days and CloudFormation still doesn’t support it.[^1]

[^1]: But they have added [a field][a3] to the queue resource, it just doesn’t do anything. Useful.

[a1]: https://aws.amazon.com/about-aws/whats-new/2021/11/amazon-sqs-server-side-encryption-keys-sse/ 
[a2]: https://github.com/hashicorp/terraform-provider-aws/blob/main/CHANGELOG.md#3690-december-09-2021
[a3]: https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-sqs-queue.html#cfn-sqs-queue-sqsmanagedsseenabled

## CloudFormation Is One Big YAML File

When you write CloudFormation you will write YAML, and you will write reams of the stuff. For the most part this YAML epic will live in one big file. There are ways around this (nested stacks being one, pre-processing another), but they all come with trade-offs. Editing one massive YAML file sucks, splitting up CloudFormation across multiple files blows. Just go bung some HCL in a folder instead. 

## CloudFormation Doesn’t Know About Your Existing Infrastructure

Compounding on the BIG YAML issue is that CloudFormation doesn’t integrate nicely with resources it doesn’t control. Need to deploy an EC2 instance to a specific subnet and add a network ACL rule?  At minimum, you’ll need to provide the subnet ID and VPC ID as parameters, even though a subnet has a 1:1 relationship with a VPC. Need to modify the route table for that VPC as well? That’s another ID you’ll need to pass in. In Terraform this can all be calculated from a single input variable for the subnet ID using data sources[^2]. By allowing the developer to “adopt” existing resources into their IaC, developers can keep their interfaces small and stable which greatly aids modularity and reuse. 

[^2]: Someone will probably comment something along the lines of "but you are increasing coupling and coupling is bad!". To them I’d like to point out that a lot of cloud infrastructure is inherently coupled and encoding those rules into your IaC makes it easier to reason about and maintain. 

## CloudFormation Doesn’t Even Know About The Infrastructure It Has Defined 

Terraform gives you almost all the information you’d ever want to know about a resource it is managing. Cloudformation will give you a name and an ARN... if you are lucky. Compare the outputs of an RDS cluster: in Terraform you will be able to reference 20 outputs from the resource (as well as around 40 inputs), in CloudFormation you can reference 4. Recently I wished to use an Aurora cluster with AWS AppSync which requires referencing the cluster’s ARN, which CloudFormation believes is on a need-to-know basis.

## CloudFormation Isn’t Expressive

OK, so I can’t reference a DB cluster’s ARN directly, I will have to recreate it myself. No big deal, right? As ARNs have a well-defined format, the naive implementation would be something like:

```yaml
!Sub "arn:aws:rds:${AWS::Region}:${AWS::AccountId}:cluster:${MyCluster}"
```

But there is a subtle problem here. By referencing the cluster directly, we get the name back which may have uppercase characters whereas ARNs must be lowercase __and there is no intrinsic function for making a string lowercase__. The [recommended solution][e1] is to use a CloudFormation transform macro which requires deploying a lambda which will then be invoked at deploy time to do the string manipulation. The equivalent Terraform: 

```terraform
lower()
```

[e1]: https://github.com/awslabs/aws-cloudformation-templates/blob/master/aws/services/CloudFormation/MacrosExamples/StringFunctions/string.yaml

If you need to do something awkward, it's usually best if you only do it once. Unfortunately, this isn’t possible in a CloudFormation template as there is no concept of a local variable. Instead, you’ll have to copy-paste these awkward hacks around any time you need to recreate a value like this. 

## CloudFormation Only Works for AWS

I don’t think there’s much to elaborate on here. I wouldn’t recommend going full “multi-cloud” just because you can with Terraform’s modular provider system, but having the option to bolt on some Cloudflare resources, or set up Active Directory groups alongside your Windows Servers is a clear win for Terraform.

But what about CloudFormation custom resources? If you are writing Infrastructure as Code, the best thing to be doing with your time is writing Infrastructure as Code. What you don’t want to be doing is writing code that allows you to write infrastructure as code, which you then deploy with its own set of infrastructure as code. Computers are quite good at recursion, humans not so much. 


## Conclusion

I’ve really only scratched the surface here. It seems like CloudFormation surprises me every single time I use it. And dev tools shouldn’t be surprising. 

### _Someone on the Internet is Wrong!_

_Whenever I read "X technology is dead" articles, my immediate reaction is often "but what about...". This is because the world isn’t the min-maxed, black and white place that some in the tech sphere would have you believe. As an aspiring paragon of nuance, I have therefore written a rebuttal to myself “[Tales of CloudFormation’s Death Have Been Greatly Exaggerated]({{< ref "/posts/2022-06-26-tales-of-cloudformations-death-have-been-greatly-exaggerated" >}})”, please have a look before deciding for yourself._

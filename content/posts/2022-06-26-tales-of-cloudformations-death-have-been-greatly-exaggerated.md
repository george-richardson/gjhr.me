---
title: "Tales of CloudFormation’s Death Have Been Greatly Exaggerated"
date: 2022-06-26 08:01:00 +0000
---

I recently saw some [sad nerd on the Internet]({{< ref "/posts/2022-06-26-cloudformation-is-dead-long-live-terraform" >}}) besmirch the good name of CloudFormation. They insinuated that this noble, battle-tested technology is actually worn out abandonware that should be discarded in favour of Terraform, the flavour of the week IaC tool. BAH! I’m here to set the record straight. 

![A skeleton takes a call while working on its laptop at a cafe](/coffeeskeleton.jpg "'I may be old, but I'm still here darnit!'")

## CloudFormation Is Always There for You (and Your Customers)

If you have an AWS account, you already have CloudFormation. This is especially useful if you want to distribute your infrastructure as code. Have a customer that wants to run your software themselves on their own AWS account? Sure! Just send them a CloudFormation template to deploy. Need to create a VPN to a customer VPC? That’s another CloudFormation template. When working with IaC in AWS, CloudFormation is the lowest common denominator, and that’s a feature in of itself. 

## CloudFormation Doesn’t Require Any Setup

Not only is CloudFormation included with your AWS account, but it also rarely requires much in the way of extra configuration. 95% of the time you can just open the web console and upload a template and watch it get deployed. Compare this to Terraform, where you’ll likely need to download the local CLI for development and configure your state storage backend or buy another SaaS like Terraform Cloud to handle it for you. When you are asking anyone who isn’t a full-time infrastructure engineer to deploy or write IaC, reducing the setup friction is a must.

## CloudFormation is YAML

As gross as YAML can sometimes be, at least it's a standard used across hundreds of systems. Asking someone to learn Terraform/HCL to deploy a single S3 bucket may be a non-starter. 

## CloudFormation Is Multi-Account 

Stack sets is a killer feature. They allow you to deploy the same CloudFormation stack across multiple accounts. This is especially useful in compliance scenarios when using a multi-account architecture, you are going to have to deploy the exact same resources to potentially dozens of accounts. With Terraform, that process would involve configuring a provider (or workspace in Terraform Cloud) for every single account and likely some custom build pipelines to boot. With stack sets, you write one YAML file and can deploy it to an AWS Organizations OU or a list of accounts. Easy. Stack sets can even automatically deploy to new accounts, streamlining your account vending process.

When combined with AWS Organizations service control policies that unwanted modification of the deployed resources, CloudFormation stack sets give you a rock solid system to implement your compliance controls with.

## Use the Right Tool for the Job

Despite my tongue in cheek introduction to this article, I do personally prefer to write Terraform most of the time. The truth is that tools have different strengths and weaknesses, and picking the correct tool for a problem is one of the indicators of a great engineer. CloudFormation can be janky and difficult to work with, but sometimes Terraform is jankier!

### _Someone on the Internet is Wrong!_

_Fall on the other side of the aisle and want to hear how CloudFormation is evil incarnate? Check out this post's sister article "[CloudFormation is Dead, Long Live Terraform]({{< ref "/posts/2022-06-26-cloudformation-is-dead-long-live-terraform" >}})"._

---
title: "Configuring SSH on EC2 through the ages"
date: 2021-11-19 07:00:00 +0000
---
Back in the dark days of 2006, a bookstore decided to rent out virtual machines. Once described as being the result of Jeff Bezos “[flailing around for an alternative to his retail operation](https://www.bloomberg.com/news/articles/2006-11-12/jeff-bezos-risky-bet)”, AWS has come a long way, but one thing from 2006 remains true: once you have a VM you often need to connect to it with SSH. 

Here I non-comprehensively chronicle the different ways you can configure and connect to an EC2 instance over SSH. You may learn some tech history too.

_Note that throughout this article I use simple `ec2 run-instances` commands, when doing this yourself you will need to ensure connectivity to an instance with security groups, routing etc._

## 2006 - The Boring Way

If you have ever used EC2 this method will be familiar. Simply create a key pair and assign it to your instance during creation. If you create your instance through the EC2 console it will even remind you to assign one and force you to confirm you have access to the private key. Once booted you can then connect to the default user for that distro with your SSH key. Couldn’t be simpler.

Aside from baking in keys with your AMI this [used to be the only way to configure SSH on your instance](https://web.archive.org/web/20070126031546/http:/developer.amazonwebservices.com/connect/servlet/KbServlet/download/533-102-990/ec2-dg-2006-10-01.pdf) and was intended to be used as a beachhead to set up a more robust SSH auth mechanism after instance creation. 

Although simple there are several downsides to using this method. It isn’t secure to use this single key with multiple users. If someone leaves your company or project and they have access to one of these SSH keys, then you will need to rotate the keys on every instance that used this key. When that is done you may find that the SSH key listed on your instance’s metadata is no longer accurate which can be infuriating when trying to log into a machine that is previously unknown to you. 

 ```bash
 # Create a new key pair and save the private key
 aws ec2 create-key-pair --key-name mikey --query 'KeyMaterial' --output text > mikey.pem
 # Run a new instance using the key pair
 aws ec2 run-instances --image-id ami-09d4a659cdd8677be --instance-type t2.micro --key-name mikey
 ```

Thankfully, technology moves inexorably onwards and these days we have more convenient methods available to us.

## ~2008 - The cloud-init Way

[Some time around 2008](https://github.com/canonical/cloud-init/tree/88236e3b646d181cd36f7e2c99c61709e221e854), Canonical, the company behind Ubuntu, started developing a system to allow auto-configuration of their official Ubuntu images on EC2 using the EC2 meta-data endpoints, including pulling down SSH keys. Since then, cloud-init has gone on to become the industry standard application to bootstrap Linux machines running in basically all public clouds.

These days there are a lot of things cloud-init can do, but for our purposes it has a few ways to inject SSH public keys on to a machine using just instance user data. 

```bash
# Save your public key to a cloud-init user data file
cat <<EOF > user-data
#cloud-config
users:
  - name: mikey
    ssh-import-id: "gh:george-richardson"
    ssh-authorized-keys: 
      - $(cat ~/.ssh/id_rsa.pub)
EOF
# Run your instance using the user data.
aws ec2 run-instances --image-id ami-09d4a659cdd8677be --instance-type t2.micro --user-data file://user-data
```

The above will start a new instance with a new user called "mikey" which uses the default ssh public key from the machine the script ran on. Great! But why is this better than the key-pair method? Although many of the same downsides still apply cloud-init gives us 3 advantages:

1. We don't have to use the default username from the AMI. 
2. We can configure more than one user.
3. [We can configure more than just the SSH key](https://cloudinit.readthedocs.io/en/latest/topics/examples.html).

Here is a more complex example of user data that would create 2 users with different keys and groups:

```yaml
#cloud-config
users:
  - name: mikey
    # This user is in the admin group
    groups: users, admin
    # This user has sudo access
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh-authorized-keys: 
      - ssh-rsa ML21t6Sl38...
  - name: nike
    groups: users   
    # This user has 2 SSH keys
    ssh-authorized-keys: 
      - ssh-rsa xOrX2aDkJr...
      - ssh-rsa ZtPxkDXWFR...
```

cloud-init only runs at launch by default, and at best we can make it run every boot to add more users. Revoking users and keys will still be an arduous process unless using [immutable infrastructure](https://www.hashicorp.com/resources/what-is-mutable-vs-immutable-infrastructure).

## ~2013 - The cloud-init X GitHub Way

[Circa 2013](https://git.launchpad.net/ssh-import-id/commit/?id=10d67e5550127a555692d1dd782aa1e45dbf45ac), the `ssh-import-id` tool used by cloud-init to import SSH keys added support to pull public SSH keys directly from GitHub. 

If you use GitHub and just want a quick and dirty instance using whatever public key you have configured on GitHub then cloud-init has got you covered. 

```yaml
#cloud-config
users:
  - name: mikey
    ssh-import-id: "gh:mikeycodes"
```

Note that this only works by default on Ubuntu/Debian as it requires the `ssh-import-id` tool to be available. I wouldn’t recommend this method for use in anything aside from personal projects, but it is nice to have. 

## 2018 - The SSM Connection Manager Way

2018 comes, 12 years after EC2s debut, and we [finally get a way to open interactive shell sessions using AWS IAM for authentication](https://aws.amazon.com/blogs/aws/new-session-manager/). [SSM Connection Manager](https://aws.amazon.com/blogs/aws/new-session-manager/) allows you to connect to your EC2 instance using your AWS IAM user and without worrying about key management. It does this through the SSM agent running on the instance calling out to AWS itself and creating a secure data tunnel. A user can then log into an interactive shell session through the console or with the AWS CLI. Because the instance is reaching out to AWS to create that initial tunnel there is no need to create inbound security rules allowing SSH on port 22 and no need for a bastion host. Because you are using AWS as a broker you can also optionally keep an auditable log in CloudWatch or S3 of all commands run through the session. 

```bash
# Create a role for instances using SSM Connection Manager
aws iam create-role --role-name SSMManaged \
  --assume-role-policy-document '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"ec2.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
aws iam create-instance-profile \
  --instance-profile-name SSMManaged
aws iam add-role-to-instance-profile \
  --instance-profile-name SSMManaged \
  --role-name SSMManaged

# Attach the AmazonSSMManagedInstanceCore policy to the role.
# This allows the instance to communicate with SSM. 
aws iam attach-role-policy \
  --role-name SSMManaged \
  --policy-arn arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore

# Create a new instance using the above role.
INSTANCE_ID=$(aws ec2 run-instances \
  --image-id ami-08edbb0e85d6a0a07 \
  --instance-type t2.micro \
  --iam-instance-profile Name=SSMManaged \
  --query 'Instances[0].InstanceId' \
  --output text)
echo INSTANCE_ID

# Connect (you'll need to wait until the instance is booted)
aws ssm start-session --target $INSTANCE_ID
```

But this isn’t SSH you say! You would be right, but it’s pretty close. If you install the [Session Manager plugin](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html) for the AWS CLI you can even [use the ssh command to connect](https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-sessions-start.html#sessions-start-ssh).

# 2019 - The EC2 Instance Connect Way

When it rains it pours, only one year later [in 2019](https://aws.amazon.com/blogs/compute/new-using-amazon-ec2-instance-connect-for-ssh-access-to-your-ec2-instances/) AWS introduce another mechanism for configuring SSH behind IAM authentication: [EC2 Instance Connect](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Connect-using-EC2-Instance-Connect.html). Perhaps because some people didn’t like the idea of AWS being able to read all of their SSH logs (unconfirmed hunch) this time we are back to end to end SSH. EC2 Instance Connect works by first making an IAM authenticated API call to AWS requesting to push an SSH public key to a specific instance. An agent running on the machine then picks up this key and temporarily installs it for a user. You can then connect directly to the machine as usual using your SSH client of choice. 

Because the connection is a proper SSH tunnel this means you will still need all the infrastructure around securing access to instances (bastion hosts, security group rules etc.) 

```bash
# Run a new instance and get its ID and AZ
aws ec2 run-instances \
  --image-id ami-08edbb0e85d6a0a07 \
  --instance-type t2.micro \
  --query 'Instances[0].{InstanceId: InstanceId, AZ: Placement.AvailabilityZone}'

# Generate a new ssh key
ssh-keygen -t rsa -f mikeys_rsa_key

# Using the details from above send over the public key
# Use the correct default user for your ami
# Wait until the instance has finished booting
aws ec2-instance-connect send-ssh-public-key \
  --availability-zone eu-west-1b \
  --instance-id i-myinstanceid \
  --instance-os-user ubuntu \
  --ssh-public-key file://mikeys_rsa_key.pub

# Get an address to connect to (in this case public IP)
aws ec2 describe-instances --instance-id i-myinstanceid \
  --query 'Reservations[0].Instances[0].PublicIpAddress' \
  --output text

# Within 60 seconds connect to the instance
ssh -i mikeys_rsa_key ubuntu@123.123.123.123
```
There is also a [`ec2instanceconnectcli`](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-connect-set-up.html#ec2-instance-connect-install-eic-CLI) package that can be used to compress all of the above into a single command e.g. `mssh@i-myinstanceid`.

As of writing EC2 Instance Connect is only supported on Ubuntu and Amazon Linux 2 out of the box.

## 20XX? The Future Way

I think EC2 Instance Connect and SSM Connection Manager go a long way to making SSH on EC2 managable but there is still room for improvement. In particular I would like to see the AWS native tools allow more user configuration similar to what cloud-init exposes. 
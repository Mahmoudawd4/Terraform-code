
# Terraform code 

Infrastructure Deployment Using Terraform deploy bastion host and private instance


## Introduction:

This terraform script aims to deploy a secure and scalable infrastructure on AWS. The infrastructure includes a Virtual Private Cloud (VPC) with public and private subnets, internet gateway, route tables, security groups, and EC2 instances. The script automates the provisioning process, enhancing repeatability and consistency.


## Assumptions:

 - AWS CLI is configured with the necessary credentials
 - Terraform is installed on the local machine
 - SSH key pair ("mykey" and "mykey.pub") is generated using ssh-keygen.


## Architecture:
The architecture includes a VPC with public and private subnets, allowing secure communication between instances. A bastion host in the public subnet facilitates SSH access to instances in the private subnet through agent forwarding.
## Terraform Coding:
### 1.Generating SSH Key Pair:


```bash
  ssh-keygen -f mykey

```

This command generates an SSH key pair ("mykey" and "mykey.pub").




## 2. Terraform Files:

### variable.tf


Defines variables such as AWS region, SSH private key, SSH public key, and AMI mappings.

```bash


variable "AWS_REGION" {
  default = "us-east-1"
}

variable "PRIVATE_KEY" {
  default = "mykey"
}

variable "PUBLIC_KEY" {
  default = "mykey.pub"
}

variable "AMIS" {
  type = map(string)
  default = {
    us-east-1 = "ami-13be557e"
    us-west-2 = "ami-06b94666"
    eu-west-1 = "ami-844e0bf7"
  }
}


```

### vpc.tf 

Creates an AWS VPC with public and private subnets, internet gateway, and route tables

```bash

# Internet VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_support   = "true"
  enable_dns_hostnames = "true"
  tags = {
    Name = "main"
  }
}

# Subnets
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.10.0/24"
  map_public_ip_on_launch = "true"
  availability_zone       = "us-east-1a"

  tags = {
    Name = "public"
  }
}


resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.20.0/24"
  map_public_ip_on_launch = "false"
  availability_zone       = "us-east-1a"

  tags = {
    Name = "private"
  }
}


# Internet GW
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}

# route tables
resource "aws_route_table" "main-public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "main-public"
  }
}

# route associations public
resource "aws_route_table_association" "main-public-1-a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.main-public.id
}


```

### securitygroup.tf:

Configures security groups for the bastion host and private instances, allowing SSH traffic.

```bash


resource "aws_security_group" "bastion-allow-ssh" {
  vpc_id      = aws_vpc.main.id
  name        = "bastion-allow-ssh"
  description = "security group for bastion that allows ssh and all egress traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "bastion-allow-ssh"
  }
}

resource "aws_security_group" "private-ssh" {
  vpc_id      = aws_vpc.main.id
  name        = "private-ssh"
  description = "security group for private that allows ssh and all egress traffic"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [ aws_security_group.bastion-allow-ssh.id ]
  }
  tags = {
    Name = "private-ssh"
  }
}


```


### provider.tf:

Specifies the AWS provider with the chosen region.


```bash
provider "aws" {
  region = var.AWS_REGION
}


```


### instance.tf:
Launches EC2 instances (bastion and private) with specified AMIs, instance types, subnets, and security groups.

```bash

resource "aws_instance" "bastion"{
  ami= var.AMIS[var.AWS_REGION]
#   ami = "ami-090fa75af13c156b4"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bastion-allow-ssh.id]

  key_name = aws_key_pair.mykeypair.key_name
}

resource "aws_instance" "private"{
  ami = var.AMIS[var.AWS_REGION]
#   ami = "ami-090fa75af13c156b4"
  instance_type = "t2.micro"
  subnet_id = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private-ssh.id]
  key_name = aws_key_pair.mykeypair.key_name
}

```
### key.tf 

```bash
resource "aws_key_pair" "mykeypair" {
  key_name   = "mykeypair"
  public_key = file(var.PUBLIC_KEY)
}


```

### versions.tf

```bash

terraform {
  required_version = ">= 0.12"
}


```
### 3. Creating the Infrastructure:

To initialize, plan, and apply the infrastructure, run the following commands in the Terraform root directory:

```bash


terraform init
terraform plan
terraform apply -auto-approve




```


 Add the SSH key to the ssh-agent


```bash

ssh-add -k "mykey"

```

SSH into the public EC2 instance:

```bash

ssh -A ec2-user@<public_instance_ip>

```

SSH into the private EC2 instance from the bastion host:

```bash

ssh ec2-user@<private_instance_ip>

```
## Authors

- [@mahmoudawd](https://github.com/Mahmoudawd4)


variable "region" { default = "ap-south-1" }
variable "key_name" { description = "EC2 key pair name" default = "your-keypair" }
variable "public_key_path" { default = "~/.ssh/id_rsa.pub" }
variable "instance_type" { default = "t3.medium" }
variable "ami" { description = "Ubuntu 22.04 AMI (replace with latest in region)" default = "ami-0abcdef1234567890" }
variable "app_count" { default = 1 }

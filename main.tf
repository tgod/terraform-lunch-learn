provider "aws" {
  version = "1.0"
  region = "us-east-1"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

module "vpc" {
  source = "modules/vpc"
  vpc_name = "${var.vpc_name}"
  cidr_block = "${var.cidr_block}"
}

module "public_subnet" {
  source = "modules/public_subnet"
  vpc_id = "${module.vpc.vpc_id}"
  vpc_name = "${var.vpc_name}"
  cidr_blocks = "${var.cidr_blocks}"
  az = "${var.az}"
}

module "http_security_group" {
  source = "modules/security_groups/http"
  vpc_name = "${var.vpc_name}"
  vpc_id = "${module.vpc.vpc_id}"
}

data "aws_ami" "ec2_ami" {
  most_recent = true
  filter {
    name = "name"
    values = [
      "ubuntu/images/hvm-ssd/ubuntu-xenial*"]
  }
  filter {
    name = "architecture"
    values = [
      "x86_64"]
  }
  filter {
    name = "hypervisor"
    values = [
      "xen"]
  }
  filter {
    name = "root-device-type"
    values = [
      "ebs"
    ]
  }
  owners = [
    "099720109477"]
}

resource "aws_instance" "web" {
  count = "${length(var.az)}"
  ami = "${data.aws_ami.ec2_ami.id}"
  instance_type = "t2.micro"
  subnet_id = "${module.public_subnet.subnet_id[count.index]}"
  associate_public_ip_address = true
  vpc_security_group_ids = ["${module.http_security_group.id}"]
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  tags {
    Name = "busybox-web"
  }
}
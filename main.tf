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

resource "aws_launch_configuration" "web_asg" {
  name = "web-asgc"
  image_id = "${data.aws_ami.ec2_ami.id}"
  instance_type = "t2.micro"
  user_data = <<-EOF
              #!/bin/bash
              echo "Hello, World" > index.html
              nohup busybox httpd -f -p 8080 &
              EOF
  security_groups = ["${module.http_security_group.id}"]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "autoscaling_group" {
  name = "web-asg"
  launch_configuration = "${aws_launch_configuration.web_asg.name}"
  max_size = "5"
  min_size = "1"
  desired_capacity = "2"
  load_balancers = ["${aws_elb.elb.name}"]
  vpc_zone_identifier = ["${module.public_subnet.subnet_id}"]
  health_check_type = "ELB"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_security_group" "elb_security_group" {
  name = "lunch-learn-elb-security-group"
  vpc_id = "${module.vpc.vpc_id}"
  ingress {
    from_port = 80
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_elb" "elb" {
  name = "lunch-learn-elb"
  subnets = ["${module.public_subnet.subnet_id}"]
  security_groups = ["${aws_security_group.elb_security_group.id}"]

  listener {
    lb_port = 80
    lb_protocol = "http"
    instance_port = "8080"
    instance_protocol = "http"
  }

  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    interval = 30
    target = "HTTP:8080/"
  }
}

output "elb_dns_name" {
  value = "${aws_elb.elb.dns_name}"
}
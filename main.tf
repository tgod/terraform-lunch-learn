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
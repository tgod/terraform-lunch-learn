provider "aws" {
  version = "1.0"
  region = "us-east-1"
  access_key = "${var.access_key}"
  secret_key = "${var.secret_key}"
}

variable "access_key" {
  type = "string"
}

variable "secret_key" {
  type = "string"
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "lunch-learn"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id = "${aws_vpc.vpc.id}"
  cidr_block = "10.0.0.0/19"
  availability_zone = "us-east-1a"
  tags {
    Name = "lunch-learn-public-subnet"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags {
    Name = "lunch-learn-igw"
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = {
    Name = "lunch-learn-public-subnet-route-table"
  }
}

resource "aws_route" "public_gateway_routes" {
  route_table_id = "${aws_route_table.public_route_table.id}"
  gateway_id = "${aws_internet_gateway.gateway.id}"
  destination_cidr_block = "0.0.0.0/0"
  lifecycle {
    create_before_destroy = true
  }
  depends_on = ["aws_route_table.public_route_table"]
}

resource "aws_route_table_association" "public_route_table_association" {
  route_table_id = "${aws_route_table.public_route_table.id}"
  subnet_id = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  lifecycle {
    create_before_destroy = true
  }
}
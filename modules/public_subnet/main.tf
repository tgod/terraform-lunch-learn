resource "aws_subnet" "public_subnet" {
  count = "${length(var.az)}"
  vpc_id = "${var.vpc_id}"
  cidr_block = "${var.cidr_blocks[count.index]}"
  availability_zone = "${var.az[count.index]}"
  tags {
    Name = "${format("%s-public-subnet-%d", var.vpc_name, count.index)}"
  }
}

resource "aws_internet_gateway" "gateway" {
  count = "${length(var.az) > 0 ? 1 : 0}"
  vpc_id = "${var.vpc_id}"
  tags {
    Name = "${format("%s-igw", var.vpc_name)}"
  }
}

resource "aws_route_table" "public_route_table" {
  count = "${length(var.az) > 0 ? 1 : 0}"
  vpc_id = "${var.vpc_id}"
  tags = {
    Name = "${format("%s-route-table", aws_internet_gateway.gateway.tags["Name"])}"
  }
}

resource "aws_route" "public_gateway_routes" {
  count = "${length(var.az) > 0 ? 1 : 0}"
  route_table_id = "${aws_route_table.public_route_table.id}"
  gateway_id = "${aws_internet_gateway.gateway.id}"
  destination_cidr_block = "0.0.0.0/0"
  lifecycle {
    create_before_destroy = true
  }
  depends_on = ["aws_route_table.public_route_table"]
}

resource "aws_route_table_association" "public_route_table_association" {
  count = "${length(var.az)}"
  route_table_id = "${aws_route_table.public_route_table.id}"
  subnet_id = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_security_group" "http" {
  name = "${format("%s-http-security-group", var.vpc_name)}"
  vpc_id = "${var.vpc_id}"
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
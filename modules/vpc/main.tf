terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

resource "aws_vpc" "this" {
  cidr_block = var.cidr_block
}

resource "aws_default_security_group" "this" {
  vpc_id = aws_vpc.this.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "all"
    cidr_blocks = [var.peer_cidr_block]
  }

  dynamic "ingress" {
    for_each = var.vpn_tunnel1_address == null ? [] : [1]
    content {
      from_port   = 500
      to_port     = 500
      protocol    = "udp"
      cidr_blocks = ["${var.vpn_tunnel1_address}/32"]
    }
  }

  dynamic "ingress" {
    for_each = var.vpn_tunnel1_address == null ? [] : [1]
    content {
      from_port   = 4500
      to_port     = 4500
      protocol    = "udp"
      cidr_blocks = ["${var.vpn_tunnel1_address}/32"]
    }
  }

  egress {
    protocol    = "all"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id
}

resource "aws_default_route_table" "this" {
  default_route_table_id = aws_vpc.this.default_route_table_id

  lifecycle {
    ignore_changes = [propagating_vgws]
  }
}

resource "aws_route" "this" {
  route_table_id = aws_default_route_table.this.id

  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_subnet" "this" {
  vpc_id = aws_vpc.this.id

  cidr_block = var.cidr_block
}

resource "aws_route_table_association" "this" {
  subnet_id      = aws_subnet.this.id
  route_table_id = aws_default_route_table.this.id
}

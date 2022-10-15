terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.34.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-west-1"
}

variable "test_content_type" {
  type    = string
  default = "text/plain"
}

variable "test_content_text" {
  type    = string
  default = "Hello, World!\n"
}

locals {
  vpc_cidr   = "10.10.0.0/16"
  module_id  = "aws-lb-fixed-test"
  http_port  = 80
  https_port = 443
}

module "aws_lb_fixed" {
  source = "../."

  aws_region = var.aws_region
  vpc_id     = aws_vpc.main.id
  subnet_ids = [
    aws_subnet.public_a.id,
    aws_subnet.public_b.id,
  ]
  security_groups = [
    aws_security_group.main.id,
  ]
  dns = {
    zone_name      = "spaceytest.xyz"
    primary_domain = "spaceytest.xyz"
  }
  listener = {
    http_ec2 = false,
    http     = true,
    https    = false,
  }
  http_port         = local.http_port
  https_port        = local.https_port
  test_content_type = var.test_content_type
  test_content_text = var.test_content_text
}

data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_security_group" "main" {
  name   = "alb_security_group"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "http"
    from_port   = local.http_port
    to_port     = local.http_port
    protocol    = "tcp"

    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https"
    from_port   = local.https_port
    to_port     = local.https_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "${local.module_id}-security-group"
  }
}

resource "aws_vpc" "main" {
  cidr_block = local.vpc_cidr

  tags = {
    Name = "${local.module_id}-vpc"
  }
}

resource "aws_subnet" "public_a" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]
}

resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.10.2.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.module_id}-igw"
  }
}

resource "aws_route_table" "public_subnets" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.module_id}-public-subnet-route-table"
  }
}

resource "aws_route_table_association" "internet_for_public_subnet_a" {
  route_table_id = aws_route_table.public_subnets.id
  subnet_id      = aws_subnet.public_a.id
}

resource "aws_route_table_association" "internet_for_public_subnet_b" {
  route_table_id = aws_route_table.public_subnets.id
  subnet_id      = aws_subnet.public_b.id
}

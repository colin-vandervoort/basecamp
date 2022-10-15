variable "vpc_id" {
  type = string
}

variable "lb_arn" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = list(string)
}

variable "http_port" {
  type    = number
  default = 80
}

variable "test_content_type" {
  type = string
}

variable "test_content_text" {
  type = string
}

resource "aws_lb_target_group_attachment" "test" {
  target_group_arn = aws_lb_target_group.ec2_listener.arn
  target_id        = aws_instance.example.id
  port             = 80
}

resource "aws_lb_target_group" "ec2_listener" {
  name     = "aws-lb-tg-http"
  port     = var.http_port
  protocol = "HTTP"
  vpc_id   = var.vpc_id
  health_check {
    interval = 70
    path     = "/index.html"
    port     = var.http_port
    protocol = "HTTP"
    matcher  = "200,202"
  }
}

resource "aws_lb_listener" "ec2_listener" {
  load_balancer_arn = var.lb_arn
  port              = var.http_port
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ec2_listener.arn
  }
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "image-type"
    values = ["machine"]
  }

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-xenial-16.04-amd64-server-*"]
  }
}

resource "aws_instance" "example" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  user_data = templatefile("${path.module}/user-data.sh", {
    instance_text = var.test_content_text
    instance_port = var.http_port
  })
  vpc_security_group_ids = var.security_group_ids
  subnet_id              = var.subnet_ids[0]

  tags = {
    Name = "lb test ec2"
  }
}

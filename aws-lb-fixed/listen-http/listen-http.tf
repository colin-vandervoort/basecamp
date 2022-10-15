variable "lb_arn" {
  type = string
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

resource "aws_lb_listener" "http" {
  load_balancer_arn = var.lb_arn
  port              = var.http_port
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = var.test_content_type
      message_body = var.test_content_text
      status_code  = 200
    }
  }
}

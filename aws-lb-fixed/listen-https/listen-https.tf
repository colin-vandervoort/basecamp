variable "lb_arn" {
  type = string
}

variable "https_port" {
  type    = number
  default = 443
}

variable "test_content_type" {
  type = string
}

variable "test_content_text" {
  type = string
}

variable "lb_dns_name" {
  type = string
}

variable "lb_zone_id" {
  type = string
}

variable "dns" {
  type = object({
    zone_name      = string
    primary_domain = string
  })
}

data "aws_route53_zone" "external" {
  name = var.dns.zone_name
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = var.lb_arn
  port              = var.https_port
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.listener_cert.arn

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = var.test_content_type
      message_body = var.test_content_text
      status_code  = 200
    }
  }
}

resource "aws_acm_certificate" "listener_cert" {
  domain_name = var.dns.primary_domain
  subject_alternative_names = [
    var.lb_dns_name,
  ]
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation_dns" {
  for_each = {
    for dvo in aws_acm_certificate.listener_cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.external.id
}

resource "aws_acm_certificate_validation" "listener_cert_validate" {
  certificate_arn         = aws_acm_certificate.listener_cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation_dns : record.fqdn]
}

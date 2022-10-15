resource "aws_lb" "origin" {
  name               = "aws-lb"
  internal           = false
  load_balancer_type = "application"

  security_groups = var.security_groups
  subnets         = var.subnet_ids
}

data "aws_route53_zone" "external" {
  name = var.dns.zone_name
}

resource "aws_route53_record" "external" {
  zone_id = data.aws_route53_zone.external.zone_id
  name    = var.dns.primary_domain
  type    = "A"

  alias {
    name                   = aws_lb.origin.dns_name
    zone_id                = aws_lb.origin.zone_id
    evaluate_target_health = true
  }
}

module "listen_http_ec2" {
  source = "./listen-http-ec2"
  count  = var.listener.http_ec2 ? 1 : 0

  vpc_id             = var.vpc_id
  subnet_ids         = var.subnet_ids
  security_group_ids = var.security_groups
  lb_arn             = aws_lb.origin.arn
  http_port          = var.http_port
  test_content_type  = var.test_content_type
  test_content_text  = var.test_content_text
}

module "listen_http" {
  source = "./listen-http"
  count  = var.listener.http ? 1 : 0

  lb_arn            = aws_lb.origin.arn
  http_port         = var.http_port
  test_content_type = var.test_content_type
  test_content_text = var.test_content_text
}

# module "listen_https" {
#   source = "./listen-https"
#   count  = var.listener.https ? 1 : 0

#   lb_arn = aws_lb.origin.arn
#   https_port        = var.https_port
#   test_content_type = var.test_content_type
#   test_content_text = var.test_content_text
#   lb_dns_name       = aws_lb.origin.dns_name
#   lb_zone_id        = aws_lb.origin.zone_id
#   dns               = var.dns
# }

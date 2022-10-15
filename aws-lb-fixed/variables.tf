variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "security_groups" {
  type = list(string)
}

variable "dns" {
  type = object({
    zone_name      = string
    primary_domain = string
  })
}

variable "listener" {
  type = object({
    http_ec2 = bool,
    http     = bool,
    https    = bool
  })
  default = {
    http_ec2 = false,
    http     = false,
    https    = true
  }

  validation {
    condition     = !var.listener.https
    error_message = "HTTPS listener not yet supported"
  }
  validation {
    condition     = (var.listener.http_ec2 || var.listener.http || var.listener.https)
    error_message = "At least one listener type must be enabled"
  }
  validation {
    condition     = !(var.listener.http_ec2 && var.listener.http)
    error_message = "Only one HTTP listener may be enabled"
  }
}

variable "http_port" {
  type    = number
  default = 80
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

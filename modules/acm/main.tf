variable "domain_name" {
  type        = string
  description = "Main domain name"
}

variable "api_subdomain" {
  type        = string
  description = "Subdomain for API"
}

variable "zone_id" {
  type        = string
  description = "Route53 Hosted Zone ID"
}

provider "aws" {
  region = "ap-northeast-1"
  alias  = "tokyo"
}

provider "aws" {
  region = "us-east-1"
  alias  = "virginia"
}

# ALB用ACM証明書 (ap-northeast-1)
resource "aws_acm_certificate" "alb" {
  provider          = aws.tokyo
  domain_name       = "${var.api_subdomain}.${var.domain_name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "alb_validation" {
  provider = aws.tokyo
  for_each = {
    for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "alb" {
  provider                = aws.tokyo
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [for record in aws_route53_record.alb_validation : record.fqdn]
}

# CloudFront用ACM証明書 (us-east-1)
resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.virginia
  domain_name       = var.domain_name
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cloudfront_validation" {
  provider = aws.tokyo
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = var.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_validation : record.fqdn]
}

output "alb_certificate_arn" {
  value = aws_acm_certificate.alb.arn
}

output "cloudfront_certificate_arn" {
  value = aws_acm_certificate.cloudfront.arn
}


resource "aws_route53_zone" "main" {
  provider = aws.tokyo
  name     = var.DomainName
  
  comment = "Hosted zone for ${var.DomainName}"
}

resource "aws_route53_record" "api" {
  provider = aws.tokyo
  zone_id  = aws_route53_zone.main.zone_id
  name     = "${var.ApiSubDomain}.${var.DomainName}"
  type     = "A"

  alias {
    name                   = aws_lb.api.dns_name
    zone_id                = aws_lb.api.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "cloudfront" {
  provider = aws.tokyo
  zone_id  = aws_route53_zone.main.zone_id
  name     = var.DomainName
  type     = "A"

  alias {
    name                   = aws_cloudfront_distribution.website.domain_name
    zone_id                = "Z2FDTNDATAQYW2"  # CloudFrontの固定HostedZoneID
    evaluate_target_health = false
  }
}

# ACM証明書のDNS検証用レコード
resource "aws_route53_record" "alb_certificate_validation" {
  provider = aws.tokyo
  for_each = {
    for dvo in aws_acm_certificate.alb.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

resource "aws_route53_record" "cloudfront_certificate_validation" {
  provider = aws.tokyo
  for_each = {
    for dvo in aws_acm_certificate.cloudfront.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  zone_id = aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  records = [each.value.record]
  ttl     = 60
}

output "hosted_zone_id" {
  value = aws_route53_zone.main.zone_id
}


# ALB用ACM証明書 (ap-northeast-1)
resource "aws_acm_certificate" "alb" {
  provider          = aws.tokyo
  domain_name       = "${var.ApiSubDomain}.${var.DomainName}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "alb" {
  provider                = aws.tokyo
  certificate_arn         = aws_acm_certificate.alb.arn
  validation_record_fqdns = [for record in aws_route53_record.alb_certificate_validation : record.fqdn]
}

# CloudFront用ACM証明書 (us-east-1)
resource "aws_acm_certificate" "cloudfront" {
  provider          = aws.virginia
  domain_name       = var.DomainName
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate_validation" "cloudfront" {
  provider                = aws.virginia
  certificate_arn         = aws_acm_certificate.cloudfront.arn
  validation_record_fqdns = [for record in aws_route53_record.cloudfront_certificate_validation : record.fqdn]
}

output "alb_certificate_arn" {
  value = aws_acm_certificate.alb.arn
}

output "cloudfront_certificate_arn" {
  value = aws_acm_certificate.cloudfront.arn
}


resource "aws_cloudfront_origin_access_control" "website" {
  provider                     = aws.global
  name                         = "OAC-${var.BucketName}"
  origin_access_control_origin_type = "s3"
  signing_behavior             = "always"
  signing_protocol             = "sigv4"
}

resource "aws_cloudfront_distribution" "website" {
  provider        = aws.global
  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_200"  # アジア、北米、ヨーロッパをカバー
  
  aliases = [var.DomainName]
  
  origin {
    domain_name              = "${var.BucketName}.s3.amazonaws.com"
    origin_id                = "S3Origin"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
    
    s3_origin_config {
      origin_access_identity = ""
    }
  }
  
  default_root_object = "index.html"
  
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "https-only"
    
    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6"  # CachingOptimized
    origin_request_policy_id = "88a5eaf4-2fd4-4709-b370-b4c650ea3fcf"  # CORS-S3Origin
  }
  
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cloudfront.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
  
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

output "cloudfront_distribution_id" {
  value = aws_cloudfront_distribution.website.id
}

output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.website.domain_name
}

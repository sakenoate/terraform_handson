
resource "aws_s3_bucket" "website" {
  provider = aws.tokyo
  bucket   = var.BucketName

  tags = {
    Name = "Website Bucket"
  }
}

resource "aws_s3_bucket_website_configuration" "website" {
  provider = aws.tokyo
  bucket   = aws_s3_bucket.website.id

  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "website" {
  provider                = aws.tokyo
  bucket                  = aws_s3_bucket.website.id
  block_public_acls       = true
  ignore_public_acls      = true
  block_public_policy     = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "website" {
  provider = aws.tokyo
  bucket   = aws_s3_bucket.website.id
  policy   = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AllowCloudFrontServicePrincipal"
        Effect    = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = "arn:aws:cloudfront::${data.aws_caller_identity.current.account_id}:distribution/${aws_cloudfront_distribution.website.id}"
          }
        }
      }
    ]
  })

  depends_on = [aws_cloudfront_distribution.website]
}

data "aws_caller_identity" "current" {}

output "bucket_name" {
  value = aws_s3_bucket.website.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.website.arn
}

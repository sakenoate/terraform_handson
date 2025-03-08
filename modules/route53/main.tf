
variable "domain_name" {
  type        = string
  description = "Main domain name"
}

provider "aws" {
  region = "ap-northeast-1"
  alias  = "tokyo"
}

resource "aws_route53_zone" "main" {
  provider = aws.tokyo
  name     = var.domain_name
  
  comment = "Hosted zone for ${var.domain_name}"
}

output "zone_id" {
  value = aws_route53_zone.main.zone_id
}

output "name_servers" {
  value = aws_route53_zone.main.name_servers
}

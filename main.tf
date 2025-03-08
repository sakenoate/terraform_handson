module "route53" {
  source = "./modules/route53"
  
  domain_name = var.DomainName
}

module "acm" {
  source = "./modules/acm"

  domain_name  = var.DomainName
  api_subdomain  = var.ApiSubDomain
  zone_id    = module.route53.zone_id
}

# 他のリソースはメインディレクトリのtfファイルで定義

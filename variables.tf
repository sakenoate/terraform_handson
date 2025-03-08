variable "DatabaseName" {
  type        = string
  description = "Database name"
  default     = "reservation_db"
  sensitive   = true
}

variable "DatabaseUsername" {
  type        = string
  description = "Database username"
  default     = "CloudTech"
  sensitive   = true
}

variable "DatabasePassword" {
  type        = string
  description = "Database password"
  default     = "Thisispassword125!#$%"
  sensitive   = true
}

variable "VPCName" {
  type        = string
  description = "VPC name"
  default     = "reservation-vpc"
}

variable "DBinboundCidrIPs" {
  type        = string
  description = "Security Group Inbound IP"
  default     = "10.0.0.0/21"
}

variable "DomainName" {
  type        = string
  description = "Main domain name"
  default     = "test-aaa-bbb.site"
}

variable "ApiSubDomain" {
  type        = string
  description = "Subdomain for API"
  default     = "api"
}

variable "BucketName" {
  type        = string
  description = "Origin Bucket name"
  default     = "my-website-bucket-569313629397"
}

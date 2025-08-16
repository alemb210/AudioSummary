variable "domain_name" {
  description = "The domain name for the Route 53 zone."
  type        = string
}

variable "aliases" {
  description = "CNAMES for the distribution (ex: example.com, www.example.com)"
  type        = list(string)
  default     = []
}

variable "cloudfront_domain_name" {
  description = "Domain name of the CloudFront distribution."
  type        = string
}

variable "cloudfront_hosted_zone_id" {
  description = "Hosted zone ID for the CloudFront distribution."
  type        = string
}

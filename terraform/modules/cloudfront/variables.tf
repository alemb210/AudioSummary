variable "s3_bucket_name" {
  description = "The name of the S3 bucket to be used as the origin for the CloudFront distribution."
  type        = string
  default     = "website-bucket-for-audio-test"
}

variable "default_root_object" {
  description = "The default root object for the CloudFront distribution."
  type        = string
  default     = "index.html"
}

variable "s3_bucket_regional_domain_name" {
  description = "The regional domain name of the S3 bucket."
  type        = string
}

variable "viewer_protocol_policy" {
  description = "The viewer protocol policy for the CloudFront distribution."
  type        = string
  default     = "redirect-to-https"
}

variable "allowed_methods" {
  description = "The allowed methods for the CloudFront distribution."
  type        = list(string)
  default     = ["GET", "HEAD", "OPTIONS"]
}

variable "cached_methods" {
  description = "The cached methods for the CloudFront distribution."
  type        = list(string)
  default     = ["GET", "HEAD"]
}

variable "compress" {
  description = "Whether to compress the content served by CloudFront."
  type        = bool
  default     = true
}

variable "min_ttl" {
  description = "The minimum time-to-live (TTL) for cached objects in CloudFront."
  type        = number
  default     = 0
}

variable "default_ttl" {
  description = "The default time-to-live (TTL) for cached objects in CloudFront."
  type        = number
  default     = 86400 #one day
}

variable "max_ttl" {
  description = "The maximum time-to-live (TTL) for cached objects in CloudFront."
  type        = number
  default     = 31536000 #one year
}

variable "aliases" {
  description = "CNAMES for the distribution (ex: example.com, www.example.com)"
  type        = list(string)
  default     = []
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS on custom domain"
  type        = string
  default     = null
}
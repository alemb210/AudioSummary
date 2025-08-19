variable "user_name" {
  type        = string
  description = "IAM user name for CI/CD (Jenkins)"
}

variable "s3_bucket_name" {
  type        = string
  description = "Website S3 bucket name to deploy assets to"
}

variable "cloudfront_distribution_arn" {
  type        = string
  description = "CloudFront distribution ARN for invalidations"
}
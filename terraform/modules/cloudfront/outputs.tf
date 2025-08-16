output "cloudfront_distribution_arn" { 
    description = "The ARN of the Cloudfront distribution"
    value       = aws_cloudfront_distribution.cdn.arn
}

output "domain_name" {
  description = "CloudFront distribution domain"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "hosted_zone_id" {
  description = "CloudFront hosted zone ID for alias records"
  value       = aws_cloudfront_distribution.cdn.hosted_zone_id
}
output "cloudfront_distribution_arn" { 
    description = "The ARN of the Cloudfront distribution"
    value       = aws_cloudfront_distribution.cdn.arn
}
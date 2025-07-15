output "s3_bucket_arn" { 
    description = "The ARN of the S3 bucket"
    value       = aws_s3_bucket.bucket.arn
}

output "s3_bucket_id" { 
    description = "The id of the S3 bucket"
    value       = aws_s3_bucket.bucket.id
}

output "s3_bucket_regional_domain_name" {
    description = "regional domain name for cloudfront integration"
    value = aws_s3_bucket.bucket.bucket_regional_domain_name
}
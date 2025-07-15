variable endpoint_path{
    description = "The endpoint path for the Lambda function."
    type        = string
}

variable s3_bucket_name {
    description = "The name of the S3 bucket to PUT"
    type        = string
}

variable aws_account_id { 
    description = "The AWS account ID."
    type        = string
    // default     = "506007020488" 
}
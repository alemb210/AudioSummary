variable "s3_bucket_name" {
  description = "The name of the S3 bucket the Lambda function will access."
  type        = string
}

variable  "lambda_function_arn" {
  description = "The ARN of the Lambda function to be invoked."
  type        = string
}

variable "lambda_role_arn" {
  description = "The ARN of the IAM role for the Lambda function."
  type        = string
}

variable "lambda_permission_id" { 
    description = "The ID of the Lambda permission allowing S3 to invoke the function."
    type        = string
}

variable "s3_bucket_policy" { 
    description = "The policy to apply to the S3 bucket."
    type        = string
}

variable "events_trigger_lambda" {
  description = "The S3 events that will trigger the Lambda function."
  type        = list(string)  
}
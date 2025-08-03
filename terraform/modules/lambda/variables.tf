variable "input_bucket_id" {
  description = "The name of the S3 bucket the Lambda function will access."
  type        = string
}

variable "lambda_role_name" {
  description = "The name of the IAM role for the Lambda function."
  type        = string
  default     = "lambda_role"
}

variable "lambda_allowed_actions" {
  description = "The actions allowed by the Lambda function."
  type        = list(string)

}

variable "lambda_allowed_resources" {
  description = "The resources the Lambda function can access."
  type        = list(string)
}

variable "lambda_function_name" {
  description = "The name of the Lambda function."
  type        = string
  default     = "my-first-lambda"
}

variable "lambda_source_file" {
  description = "The path to the Lambda function source code."
  type        = string
  default     = "src/lambda.py"
}

variable "lambda_handler" {
  description = "The handler function in lambda.py."
  type        = string
  default     = "lambda.lambda_handler"
}

variable "lambda_runtime" {
  description = "The runtime environment for the Lambda function."
  type        = string
  default     = "python3.8"
}

variable "secret_arn" {
  description = "The ARN of the secret in Secrets Manager."
  type        = string
}

variable "caller_bucket_arn" {
  description = "The ARN of the S3 bucket that will trigger the Lambda."
  type        = string
}

variable "output_bucket_id" { 
  description = "The ID of the S3 bucket where the Lambda function will put the transcribed file."
  type        = string
}

variable "lambda_policy_name" {
  description = "The name of the IAM policy for the Lambda function."
  type        = string
  default     = "lambda_policy"
}

variable "lambda_timeout" {
  description = "The timeout for the Lambda function in seconds."
  type        = number
  default     = 3
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table to store WebSocket connections."
  type        = string
  default     = "websocket-connections"
}
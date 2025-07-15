output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.function.arn
}

output "lambda_function_invoke_arn" {
  description = "The Invoke ARN of the Lambda function"
  value       = aws_lambda_function.function.invoke_arn
}

output "lambda_permission_allow_s3" {
  value = aws_lambda_permission.allow_s3.id
}

output "lambda_role_arn" { 
  description = "The ARN of the IAM role for the Lambda function"
  value       = aws_iam_role.lambda_role.arn
}
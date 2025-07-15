#ARN of the secret for use in iam policy
output "secret_arn" {
  description = "The ARN of the secret"
  value       = data.aws_secretsmanager_secret.api_key.arn
}
# Data source to retrieve the secret from AWS Secrets Manager
data "aws_secretsmanager_secret" "api_key" { 
  name = var.secret_name
}

# # Data source to retrieve the latest version of the secret
# data "aws_secretsmanager_secret_version" "api_key_version" {
#   secret_id = data.aws_secretsmanager_secret.api_key.id
# }

# # API key variabalized for use in lambda
# output "secret_value" {
#   description = "The value of the secret"
#   value       = data.aws_secretsmanager_secret_version.api_key_version.secret_string
#   sensitive   = true
# }



# #Key Management Service (KMS) key for encrypting secrets
# resource "aws_kms_key" "kms_key" {
#   description             = "KMS key for credentials rotation"
#   enable_key_rotation     = var.key_rotation
#   deletion_window_in_days = var.deletion_window_in_days
# }

# # Create a secret in AWS Secrets Manager, which stores the API key for our AI service
# resource "aws_secretsmanager_secret" "api_key" {
#   name = var.secret_name
#   description = var.secret_description
#   kms_key_id = aws_kms_key.kms_key.key_id # Use the KMS key for encryption
# }

# # Create a version of the secret with the actual API key value (Secrets have versions that can be rotated or updated)
# resource "aws_secretsmanager_secret_version" "api_key_version" {
#   secret_id     = aws_secretsmanager_secret.api_key.id
#   secret_string = var.ai_api_key # Replace with API key 
# }

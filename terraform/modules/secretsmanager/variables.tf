variable secret_name {
    description = "The name of the secret in Secrets Manager."
    type        = string
}

#Accessed through environment variable
# variable ai_api_key {
#     description = "API key for AI service"
#     type        = string
#     sensitive   = true
# }

# variable key_rotation {
#     description = "Enable key rotation for the KMS key." 
#     type = bool
#     default = true
# }

# variable deletion_window_in_days {
#     description = "The number of days before the KMS key is deleted."
#     type        = number
#     default     = 7
# }

# variable secret_description {
#     description = "A description for the secret in Secrets Manager."
#     type        = string
#     default     = "API key for AI service"
# }

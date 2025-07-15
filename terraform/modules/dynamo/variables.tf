variable "table_name" {
  description = "Name of the DynamoDB table"
  type        = string
}

variable "billing_mode" {
  description = "Billing mode for the DynamoDB table"
  type        = string
}

variable "hash_key" {
  description = "Hash key for the DynamoDB table"
  type        = string
}

variable "attributes" {
  description = "List of attributes for the DynamoDB table"
  type = list(object({
    name = string
    type = string
  }))
  default = []
}

variable "global_secondary_indices" {
  description = "List of global secondary indices for the DynamoDB table"
  type = list(object({
    name            = string
    hash_key        = string
    projection_type = string
  }))
  default = []
}
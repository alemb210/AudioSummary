variable "websocket_api_name" {
  description = "Name of the WebSocket API"
  type        = string
}

variable "route_selection_expression" {
  description = "Expression used to select the route for incoming requests"
  type        = string
  default     = "$request.body.action"
}

variable "connect_lambda_arn" {
  description = "ARN of the Lambda function to handle WebSocket connections"
  type        = string
}

variable "disconnect_lambda_arn" {
  description = "ARN of the Lambda function to handle WebSocket disconnections"
  type        = string
}

variable "aws_account_id" {
  description = "The AWS account ID."
  type        = string
}

variable "connect_lambda_name" {
  description = "Name of the Lambda function for handling WebSocket connections"
  type        = string
}

variable "disconnect_lambda_name" {
  description = "Name of the Lambda function for handling WebSocket disconnections"
  type        = string
}
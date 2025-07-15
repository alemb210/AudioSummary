variable "websocket_api_name" {
  description = "Name of the WebSocket API"
  type        = string
}

variable "route_selection_expression" {
  description = "Expression used to select the route for incoming requests"
  type        = string
  default     = "$request.body.action"
}

variable "custom_route_key" {
  description = "Custom route key for the WebSocket API"
  type        = string
}
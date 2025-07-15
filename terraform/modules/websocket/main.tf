resource "aws_apigatewayv2_api" "websocket_api" {
  name                       = var.websocket_api_name
  protocol_type              = "WEBSOCKET"
  route_selection_expression = var.route_selection_expression
}

resource "aws_apigatewayv2_stage" "stage" {
  api_id      = aws_apigatewayv2_api.websocket_api.id
  name        = "dev"
}

resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$connect"
}

resource "aws_apigatewayv2_route" "disconnect" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$disconnect"
}

#route for frontend to signal it is awaiting an analysis file
resource "aws_apigatewayv2_route" "custom_route" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = var.custom_route_key
} 



# WebSocket Implementation for AudioSummary - Conceptual Overview
# Architecture Overview
# The WebSocket implementation for your AudioSummary application would work as follows:

# File Upload & WebSocket Connection

# User uploads an audio file through your frontend
# Frontend immediately establishes a WebSocket connection
# Frontend sends the file ID through this connection to register interest in receiving notifications
# Connection & File Tracking

# Backend stores the WebSocket connection ID and associates it with the uploaded file ID
# This creates a mapping between "which user/connection is waiting for which file's analysis"
# Processing Pipeline

# Audio file is processed through your existing pipeline (transcription → analysis)
# When analysis is complete, a pre-signed URL is generated for the result file
# Notification System

# When the analysis is complete, the system looks up which connections are waiting for this file
# The pre-signed URL is sent through the WebSocket connection to the frontend
# Frontend receives the URL and can immediately display or download the results
# Key Components
# WebSocket API Gateway

# Handles WebSocket connections, message routing, and connection management
# Supports the standard routes ($connect, $disconnect) plus custom routes
# Connection Management

# Stores connection IDs when users connect
# Associates connections with specific file IDs
# Removes connections when users disconnect
# File Registration

# Allows frontend to register interest in a specific file's analysis results
# Maps the connection to the file being processed
# Notification Mechanism

# Triggered when analysis is complete
# Looks up which connections are waiting for the file
# Sends the pre-signed URL to those connections
# Pre-signed URL Generation

# Creates temporary, secure access to the analysis results
# Limited-time access that doesn't require permanent public accessibility
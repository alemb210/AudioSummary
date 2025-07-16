#for log arn
data "aws_region" "current" {}

#role for API gateway which we will use to enable CloudWatch logging
resource "aws_iam_role" "api_gateway_role" {
  name = "WebSocketAPILoggingRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "apigateway.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

#policy for CloudWatch logging
resource "aws_iam_policy" "api_gateway_policy" {
  name = "WebSocketAPILoggingPolicy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["logs:*"],
        Resource = "*"
      }
    ]
  })
}

#enable logging 
resource "aws_iam_role_policy_attachment" "attach_logging_policy" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = aws_iam_policy.api_gateway_policy.arn
}

resource "aws_api_gateway_account" "account_settings" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_role.arn
}


resource "aws_apigatewayv2_api" "websocket_api" {
  name                       = var.websocket_api_name
  protocol_type              = "WEBSOCKET"
  route_selection_expression = var.route_selection_expression
}

#dev stage for API Gateway deployment
resource "aws_apigatewayv2_stage" "stage" {
  deployment_id = aws_apigatewayv2_deployment.deployment.id #associate the deployment with the stage
  api_id        = aws_apigatewayv2_api.websocket_api.id
  name          = "dev"
  # Enable CloudWatch logging for the API Gateway stage
  access_log_settings {
    destination_arn = "arn:aws:logs:${data.aws_region.current.name}:${var.aws_account_id}:log-group:/aws/api-gateway/${aws_apigatewayv2_api.websocket_api.name}"
    format = jsonencode({
      requestId    = "$context.requestId",
      ip           = "$context.identity.sourceIp",
      httpMethod   = "$context.httpMethod",
      resourcePath = "$context.resourcePath",
      status       = "$context.status",
      responseTime = "$context.responseLatency",
      userAgent    = "$context.identity.userAgent"
    })
  }

  default_route_settings {
    logging_level            = "INFO"
    detailed_metrics_enabled = true
    throttling_burst_limit   = 100
    throttling_rate_limit    = 50
  }

  depends_on = [aws_api_gateway_account.account_settings]
}

resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.connect_integration.id}"
}

#integrate lambda function when connect route is hit
resource "aws_apigatewayv2_integration" "connect_integration" {
  api_id           = aws_apigatewayv2_api.websocket_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.connect_lambda_arn
}

resource "aws_apigatewayv2_route" "disconnect" {
  api_id    = aws_apigatewayv2_api.websocket_api.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.disconnect_integration.id}"
}

#https://docs.aws.amazon.com/apigateway/latest/developerguide/apigateway-websocket-api-route-keys-connect-disconnect.html#apigateway-websocket-api-routes-about-disconnect
#"$disconnect is a best-effort event -- API Gateway cannot guarantee delivery" so we use a dummy Lambda as to not rely on it for critical operations
resource "aws_apigatewayv2_integration" "disconnect_integration" {
  api_id           = aws_apigatewayv2_api.websocket_api.id
  integration_type = "AWS_PROXY"
  integration_uri  = var.disconnect_lambda_arn
}

#Creates a deployment (snapshot) of API Gateway configuration that can be associated with a stage (dev, prod) 
resource "aws_apigatewayv2_deployment" "deployment" {
  api_id = aws_apigatewayv2_api.websocket_api.id

  triggers = { #Any changes will trigger a redeployment of the API Gateway
    redeployment = sha1(jsonencode([
      aws_apigatewayv2_route.connect,
      aws_apigatewayv2_route.disconnect,
      aws_apigatewayv2_integration.connect_integration,
      aws_apigatewayv2_integration.disconnect_integration,
      aws_lambda_permission.connect_permission,
      aws_lambda_permission.disconnect_permission
    ]))
  }

  lifecycle { #Ensure uptime during redeployments by creating before destroying
    create_before_destroy = true
  } #Deployment must wait for the methods and integration to be created
  depends_on = [
    aws_apigatewayv2_route.connect,
    aws_apigatewayv2_route.disconnect,
    aws_apigatewayv2_integration.connect_integration,
    aws_apigatewayv2_integration.disconnect_integration,
    aws_lambda_permission.connect_permission,
    aws_lambda_permission.disconnect_permission
  ]
}

resource "aws_lambda_permission" "connect_permission" {
  statement_id  = "ExecuteConnectLambdaFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.connect_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "disconnect_permission" {
  statement_id  = "ExecuteDisconnectLambdaFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = var.disconnect_lambda_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.websocket_api.execution_arn}/*/*"
}

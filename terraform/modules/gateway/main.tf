
#API gateway module
data "aws_region" "current" {}

#Access policy for API Gateway to access S3
resource "aws_iam_policy" "api_gateway_access" {
  name        = "APIGatewayAccessPolicy"
  description = "Policy to allow API Gateway to access S3"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = "s3:PutObject",
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/*"
      },
      { #Enable logging as well
        Effect = "Allow",
        Action = [
          "logs:*"
        ],
        Resource = "*"
      }
    ]
  })
}

#IAM role that API Gateway assumes to access S3
resource "aws_iam_role" "api_gateway_role" {
  name = "APIGatewayAccessRole"
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

#Attach policy to role, allowing API Gateway to assume it
resource "aws_iam_role_policy_attachment" "attach_api_gateway_policy" {
  role       = aws_iam_role.api_gateway_role.name
  policy_arn = aws_iam_policy.api_gateway_access.arn
}

resource "aws_api_gateway_account" "account_settings" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_role.arn
}

#REST API resource
resource "aws_api_gateway_rest_api" "api" {
  name        = "MyAPI"
  description = "API for uploading files to S3 bucket"

  binary_media_types = [
    "audio/mpeg", # For MP3 files
    "audio/mp4",  # For MP4 files
    "audio/wav",  # For WAV files
    "audio/flac",  # For FLAC files
    "multipart/form-data", # For file uploads (Testing purposes) This one works, but not mp3 (for some reason)
  ]
}


resource "aws_api_gateway_resource" "filename_resource" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "{filename}" # Dynamic path parameter for the file name
}

#Use this to create the different methods and any authorization needed. 
#We use PUT to upload files, and authenticate using AWS_IAM
resource "aws_api_gateway_method" "put_method" {
  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = aws_api_gateway_resource.filename_resource.id
  http_method      = "PUT"
  authorization    = "NONE"
  api_key_required = false

  request_parameters = {
    "method.request.path.filename" = true
  }

}

#For the AWS_PROXY, you have to use the integration_http_method of POST.
#Connect the s3 bucket to the API gateway
resource "aws_api_gateway_integration" "integration" {
  rest_api_id             = aws_api_gateway_rest_api.api.id
  resource_id             = aws_api_gateway_resource.filename_resource.id
  http_method             = aws_api_gateway_method.put_method.http_method
  integration_http_method = "PUT"
  type                    = "AWS" #Forwards the request
  uri                     = "arn:aws:apigateway:${data.aws_region.current.name}:s3:path/${var.s3_bucket_name}/{filename}"

  credentials = aws_iam_role.api_gateway_role.arn #IAM role that API Gateway assumes to access S3

  request_parameters = {
    "integration.request.path.filename" = "method.request.path.filename"
  }

  #passthrough_behavior = "WHEN_NO_MATCH"
  passthrough_behavior = "WHEN_NO_TEMPLATES" # Adjusted for binary payloads
  content_handling     = "CONVERT_TO_BINARY" # Converts base64 to binary
}

#Creates a deployment (snapshot) of API Gateway configuration that can be associated with a stage (dev, prod) 
resource "aws_api_gateway_deployment" "deployment" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  triggers = { #Any changes will trigger a redeployment of the API Gateway
    #redeployment = sha1(jsonencode(aws_api_gateway_rest_api.api.body))
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.filename_resource,
      aws_api_gateway_method.put_method,
      aws_api_gateway_integration.integration,
      aws_api_gateway_method_response.method_response,
      aws_api_gateway_integration_response.integration_response,
      aws_api_gateway_method.options_method,
      aws_api_gateway_method_response.options_response,
      aws_api_gateway_integration.options_integration,
      aws_api_gateway_integration_response.options_response
    ]))
  }

  lifecycle { #Ensure uptime during redeployments by creating before destroying
    create_before_destroy = true
  } #Deployment must wait for the method and integration to be created
  depends_on = [aws_api_gateway_method.put_method, aws_api_gateway_integration.integration]
}

#allows us to deploy the API gateway and give the stage a name to access the endpoints.
resource "aws_api_gateway_stage" "stage" {
  deployment_id = aws_api_gateway_deployment.deployment.id
  rest_api_id   = aws_api_gateway_rest_api.api.id
  stage_name    = "dev"

  # Enable CloudWatch logging for the API Gateway stage
  access_log_settings {
    destination_arn = "arn:aws:logs:${data.aws_region.current.name}:${var.aws_account_id}:log-group:/aws/api-gateway/${aws_api_gateway_rest_api.api.name}"
    format          = jsonencode({
      requestId       = "$context.requestId",
      ip              = "$context.identity.sourceIp",
      httpMethod      = "$context.httpMethod",
      resourcePath    = "$context.resourcePath",
      status          = "$context.status",
      responseTime    = "$context.responseLatency",
      userAgent       = "$context.identity.userAgent"
    })
  }

  depends_on = [aws_api_gateway_account.account_settings]
}

#Method settings for the API Gateway stage to configure logging
resource "aws_api_gateway_method_settings" "method_settings" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.stage.stage_name
  method_path = "${aws_api_gateway_resource.filename_resource.path_part}/${aws_api_gateway_method.put_method.http_method}"

  settings {
    metrics_enabled        = true
    logging_level          = "INFO"
    data_trace_enabled     = true
    throttling_burst_limit = 1000
    throttling_rate_limit  = 1000
  }
}

#HTTP method response for the API Gateway successful PUT
resource "aws_api_gateway_method_response" "method_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.filename_resource.id
  http_method = aws_api_gateway_method.put_method.http_method
  status_code = "200" # Define HTTP 200 response

  response_parameters = {
    "method.response.header.Content-Type" = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

#Map responses from s3 bucket to API Gateway http responses
resource "aws_api_gateway_integration_response" "integration_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.filename_resource.id
  http_method = aws_api_gateway_method.put_method.http_method
  status_code = aws_api_gateway_method_response.method_response.status_code

  response_parameters = {
    "method.response.header.Content-Type" = "'application/json'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'PUT,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'https://d3r6m9db3kpdda.cloudfront.net'"  
  }

  response_templates = {
    "application/json" = jsonencode(
      {
        message = "File uploaded successfully!"
      }
    )
  }
  
  depends_on = [aws_api_gateway_method_response.method_response]
}

#CORS configuration:
# OPTIONS HTTP method.
resource "aws_api_gateway_method" "options_method" {
  rest_api_id      = aws_api_gateway_rest_api.api.id
  resource_id      = aws_api_gateway_resource.filename_resource.id
  http_method      = "OPTIONS"
  authorization    = "NONE"
  api_key_required = false
}

# OPTIONS method response.
resource "aws_api_gateway_method_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.filename_resource.id
  http_method = aws_api_gateway_method.options_method.http_method
  status_code = "200"
  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }
}

# OPTIONS integration.
resource "aws_api_gateway_integration" "options_integration" {
  rest_api_id          = aws_api_gateway_rest_api.api.id
  resource_id          = aws_api_gateway_resource.filename_resource.id
  http_method          = "OPTIONS"
  type                 = "MOCK"
  passthrough_behavior = "WHEN_NO_MATCH"
  request_templates = {
    "application/json" : "{\"statusCode\": 200}"
  }

  depends_on = [aws_api_gateway_method.options_method]
}

# OPTIONS integration response.
resource "aws_api_gateway_integration_response" "options_response" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.filename_resource.id
  http_method = aws_api_gateway_integration.options_integration.http_method
  status_code = "200"
  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'PUT,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'https://d3r6m9db3kpdda.cloudfront.net'"
  }
}

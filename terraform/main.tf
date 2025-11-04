data "aws_caller_identity" "current" {} //used for dynamic ARN generation and programatic account id retrieval
data "aws_region" "current" {}

module "vpc" {
  source = "./modules/vpc"
}


#Lambda - Transcriber function
#triggered by PUT into upload bucket
module "lambda_transcriber" {
  source                 = "./modules/lambda"
  input_bucket_id        = module.upload_bucket.s3_bucket_id #The id of the bucket the Lambda reads from
  lambda_function_name   = "transcription-function"
  lambda_handler         = "lambda.handler"
  lambda_runtime         = "nodejs16.x"
  lambda_role_name       = "transcription-lambda-role"
  lambda_policy_name     = "transcription-lambda-policy"
  lambda_source_file     = "modules/lambda/transcription-function/"
  secret_arn             = module.secretsmanager.secret_arn
  caller_bucket_arn      = module.upload_bucket.s3_bucket_arn       #The arn of the bucket that invokes the Lambda
  output_bucket_id       = module.transcription_bucket.s3_bucket_id #The id of the bucket the lambda will write to
  lambda_allowed_actions = ["s3:GetObject", "s3:PutObject", "transcribe:StartTranscriptionJob"]
  lambda_allowed_resources = [
    "arn:aws:s3:::${module.upload_bucket.s3_bucket_id}/*", "arn:aws:s3:::${module.transcription_bucket.s3_bucket_id}/*",
    "arn:aws:transcribe:us-east-1:506007020488:transcription-job/*"
  ]
}


#Lambda - Analysis function
#triggered by PUT into transcription bucket
module "lambda_analysis" {
  source                   = "./modules/lambda"
  input_bucket_id          = module.transcription_bucket.s3_bucket_id
  lambda_function_name     = "analysis-function"
  lambda_handler           = "lambda.handler"
  lambda_runtime           = "nodejs16.x"
  lambda_role_name         = "analysis-lambda-role"
  lambda_policy_name       = "analysis-lambda-policy"
  lambda_source_file       = "modules/lambda/analysis-function/"
  secret_arn               = module.secretsmanager.secret_arn
  caller_bucket_arn        = module.transcription_bucket.s3_bucket_arn
  output_bucket_id         = module.transcription_bucket.s3_bucket_id #we will change this later, for now we will not implement write funcitonality
  lambda_allowed_actions   = ["s3:GetObject", "s3:PutObject", "bedrock:InvokeModel"]
  lambda_allowed_resources = ["*"]
  lambda_timeout           = 30
}

module "lambda_presign" {
  source                 = "./modules/lambda"
  input_bucket_id        = module.analysis_bucket.s3_bucket_id #The id of the bucket Lambda gets a file from
  lambda_function_name   = "presign-function"
  lambda_handler         = "lambda.handler"
  lambda_runtime         = "nodejs16.x"
  lambda_role_name       = "presign-lambda-role"
  lambda_policy_name     = "presign-lambda-policy"
  lambda_source_file     = "modules/lambda/presign-function/"
  secret_arn             = module.secretsmanager.secret_arn
  caller_bucket_arn      = module.analysis_bucket.s3_bucket_arn #The arn of the bucket that invokes the Lambda
  output_bucket_id       = module.analysis_bucket.s3_bucket_id  #The id of the bucket the lambda will write to
  lambda_allowed_actions = ["s3:GetObject", "dynamodb:GetItem", "execute-api:ManageConnections"]
  lambda_allowed_resources = [
    "arn:aws:s3:::${module.analysis_bucket.s3_bucket_id}/*",
    module.dynamo.dynamodb_table_arn,
    "arn:aws:execute-api:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:${module.websocket.websocket_api_id}/*/@connections/*"

  ]
  dynamodb_table_name = module.dynamo.dynamodb_table_name 
  websocket_api_endpoint = "https://40nrw5iine.execute-api.us-east-1.amazonaws.com/dev"
  
  }


module "secretsmanager" {
  source      = "./modules/secretsmanager"
  secret_name = "ai_api_key"
}

module "upload_bucket" {
  source                = "./modules/s3bucket"
  s3_bucket_name        = "upload-bucket-for-audio-test"
  lambda_function_arn   = module.lambda_transcriber.lambda_function_arn #lambda function to trigger
  lambda_permission_id  = module.lambda_transcriber.lambda_permission_allow_s3
  lambda_role_arn       = module.lambda_transcriber.lambda_role_arn
  events_trigger_lambda = ["s3:ObjectCreated:*"]
  ttl_days = 1
  s3_bucket_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { #Allow API Gateway to PUT to S3
          Service = "apigateway.amazonaws.com",
        },
        Action   = "s3:PutObject",
        Resource = "${module.upload_bucket.s3_bucket_arn}/*"
      }
    ]
  })
}

module "transcription_bucket" {
  source                = "./modules/s3bucket"
  s3_bucket_name        = "transcription-bucket-for-audio-test"
  lambda_function_arn   = module.lambda_analysis.lambda_function_arn
  lambda_permission_id  = module.lambda_analysis.lambda_permission_allow_s3
  lambda_role_arn       = module.lambda_analysis.lambda_role_arn
  events_trigger_lambda = ["s3:ObjectCreated:*"]
  ttl_days = 1
  s3_bucket_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = { #Allow Transcribe to PUT to S3
          Service = "transcribe.amazonaws.com",
        },
        Action   = "s3:PutObject",
        Resource = "${module.transcription_bucket.s3_bucket_arn}/*"
      }
    ]
  })
}

module "analysis_bucket" {
  source         = "./modules/s3bucket"
  s3_bucket_name = "analysis-bucket-for-audio-test"
  #lambda_function_arn   = module.lambda_analysis.lambda_function_arn #replace with presigned url lambda function later
  #lambda_permission_id  = module.lambda_analysis.lambda_permission_allow_s3
  #lambda_role_arn       = module.lambda_analysis.lambda_role_arn
  lambda_function_arn   = module.lambda_presign.lambda_function_arn
  lambda_permission_id  = module.lambda_presign.lambda_permission_allow_s3
  lambda_role_arn       = module.lambda_presign.lambda_role_arn
  events_trigger_lambda = ["s3:ObjectCreated:*"]
  ttl_days = 1
  #events_trigger_lambda = [] #stub so we dont trigger the wrong lambda
  s3_bucket_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          AWS = module.lambda_presign.lambda_role_arn #allow lambda to access and generate presigned url
        },
        Action   = "s3:GetObject",
        Resource = "${module.analysis_bucket.s3_bucket_arn}/*"
      },
      {
        Effect = "Allow",
        Principal = {
          AWS = module.lambda_analysis.lambda_role_arn #allow analysis lambda to upload bedrock output
        },
        Action   = "s3:PutObject",
        Resource = "${module.analysis_bucket.s3_bucket_arn}/*"
      }
    ]
  })
}


module "website_bucket" {
  source                = "./modules/s3bucket"
  s3_bucket_name        = "website-bucket-for-audio-test"
  lambda_function_arn   = module.lambda_transcriber.lambda_function_arn #lambda function to trigger
  lambda_permission_id  = module.lambda_transcriber.lambda_permission_allow_s3
  lambda_role_arn       = module.lambda_transcriber.lambda_role_arn
  events_trigger_lambda = []
  ttl_days = 0
  s3_bucket_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${module.website_bucket.s3_bucket_arn}/*"
        Condition = {
          StringEquals = {
            "AWS:SourceArn" = module.s3_cloudfront.cloudfront_distribution_arn
          }
        }
      }
    ]
  })
}

module "s3_cloudfront" {
  source                         = "./modules/cloudfront"
  s3_bucket_name                 = module.website_bucket.s3_bucket_id
  default_root_object            = "index.html"
  s3_bucket_regional_domain_name = module.website_bucket.s3_bucket_regional_domain_name
  viewer_protocol_policy         = "redirect-to-https"
  allowed_methods                = ["GET", "HEAD", "OPTIONS"]
  cached_methods                 = ["GET", "HEAD"]
  compress                       = true
  min_ttl                        = 0
  default_ttl                    = 3600 #one day
  max_ttl                        = 86400 #one year
  aliases            = ["mrmeeting.net", "www.mrmeeting.net"]
  acm_certificate_arn = module.acm.certificate_arn
}

module "gateway" {
  source         = "./modules/gateway"
  endpoint_path  = "upload"
  aws_account_id = data.aws_caller_identity.current.account_id
  s3_bucket_name = "upload-bucket-for-audio-test"
}

module "websocket" {
  source                     = "./modules/websocket"
  websocket_api_name         = "websocket-api"
  route_selection_expression = "$request.body.action"
  connect_lambda_arn         = module.lambda_connect.lambda_function_arn
  connect_lambda_name        = module.lambda_connect.lambda_function_name
  disconnect_lambda_arn      = module.lambda_disconnect.lambda_function_arn
  disconnect_lambda_name     = module.lambda_disconnect.lambda_function_name
  aws_account_id = data.aws_caller_identity.current.account_id
}

module "dynamo" {
  source       = "./modules/dynamo"
  table_name   = "websocket-connections"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "fileId"
  attributes = [
    {
    name = "fileId"
    type = "S" # String
    } 
  ]
}


module "lambda_connect" {
  source               = "./modules/lambda"
  input_bucket_id      = module.upload_bucket.s3_bucket_id #unused
  lambda_function_name = "connect-integration"
  lambda_handler       = "lambda.handler"
  lambda_runtime       = "nodejs16.x"
  lambda_role_name     = "websocket-connect-lambda-role"
  lambda_policy_name   = "websocket-connect-lambda-policy"
  lambda_source_file   = "modules/lambda/connect-integration/"
  secret_arn           = module.secretsmanager.secret_arn
  caller_bucket_arn    = module.upload_bucket.s3_bucket_arn #unused
  output_bucket_id     = module.upload_bucket.s3_bucket_id  #unused
  lambda_allowed_actions = ["dynamodb:PutItem"]
  lambda_allowed_resources = [module.dynamo.dynamodb_table_arn]
  dynamodb_table_name = module.dynamo.dynamodb_table_name 
}

module "lambda_disconnect" {
  source                   = "./modules/lambda"
  input_bucket_id          = module.upload_bucket.s3_bucket_id #unused
  lambda_function_name     = "disconnect-integration"
  lambda_handler           = "lambda.handler"
  lambda_runtime           = "nodejs16.x"
  lambda_role_name         = "websocket-disconnect-lambda-role"
  lambda_policy_name       = "websocket-disconnect-lambda-policy"
  lambda_source_file       = "modules/lambda/disconnect-integration/"
  secret_arn               = module.secretsmanager.secret_arn
  caller_bucket_arn        = module.upload_bucket.s3_bucket_arn #unused
  output_bucket_id         = module.upload_bucket.s3_bucket_id  #unused
  lambda_allowed_actions   = ["logs:*"]
  lambda_allowed_resources = ["arn:aws:logs:*"]
}

module "route53" {
  source       = "./modules/route53"
  domain_name  = "mrmeeting.net" 
  aliases            = ["mrmeeting.net", "www.mrmeeting.net"]
  cloudfront_domain_name = module.s3_cloudfront.domain_name
  cloudfront_hosted_zone_id = module.s3_cloudfront.hosted_zone_id
}

module "acm" {
  source      = "./modules/acm"
  domain_name = "mrmeeting.net" 
  sans        = ["www.mrmeeting.net"]
  zone_id     = module.route53.zone_id
}

module "jenkins" {
  source = "./modules/jenkins"
  user_name = "jenkins-user"
  s3_bucket_name = module.website_bucket.s3_bucket_id
  cloudfront_distribution_arn = module.s3_cloudfront.cloudfront_distribution_arn
}


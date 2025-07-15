#Create an IAM policy document for our Lambda function
#Allows Lambda to assume an IAM role that is defined later on
#Trust policy
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

#Permissions policy -- to be separated from the trust policy
data "aws_iam_policy_document" "lambda_policy" {
  statement {
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]

    resources = ["arn:aws:logs:*:*:*"]
  }

  statement {
    effect = "Allow"

    # actions = [
    #   "s3:GetObject", #read audio files from input bucket
    #   "s3:PutObject", #write transcription results to output bucket
    #   "transcribe:StartTranscriptionJob" 
    # ]

    # resources = [
    #   "arn:aws:s3:::${var.input_bucket_id}/*",
    #   "arn:aws:s3:::${var.output_bucket_id}/*",
    #   "arn:aws:transcribe:us-east-1:506007020488:transcription-job/*" #allow access to all transcription jobs
    # ]

    actions = var.lambda_allowed_actions
    resources = var.lambda_allowed_resources 
  }
  # permissions for Secrets Manager
  statement {
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [
      var.secret_arn # Pass the ARN of the secret as a variable
    ]
  }
}

#Allow S3 to invoke the Lambda function
#This is needed for the S3 bucket to trigger the Lambda function
resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "s3.amazonaws.com"  
  source_arn    = var.caller_bucket_arn
}

#The role Lambda will assume
resource "aws_iam_role" "lambda_role" {
  name               = var.lambda_role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json #Read from assume_role_policy defined above
}

#The policy that will be attached to the role
resource "aws_iam_policy" "lambda_policy" {
  name        = var.lambda_policy_name
  description = "IAM policy for Lambda function"
  policy      = data.aws_iam_policy_document.lambda_policy.json #Read from lambda_policy defined above
}

#Attach the policy to the role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

#Zip the Lambda function code for deployment
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir = var.lambda_source_file          # Path to your Lambda function code
  output_path = "${path.module}/${var.lambda_function_name}/lambda.zip" # Output path for the zip file
}

#Create the Lambda function for deployment
resource "aws_lambda_function" "function" {
  filename      = data.archive_file.lambda_zip.output_path
  function_name = var.lambda_function_name
  role          = aws_iam_role.lambda_role.arn
  handler       = var.lambda_handler # The handler function in lambda.py
  runtime       = var.lambda_runtime
  timeout       = var.lambda_timeout
  depends_on    = [aws_iam_role_policy_attachment.lambda_policy_attachment] # Ensure the role is attached before creating the Lambda function]

  source_code_hash = filebase64sha256(data.archive_file.lambda_zip.output_path) #redeploy if code changes

  environment {
    variables = {
      LANGUAGE_CODE = "en-US"                        # Specify the language code for transcription
      OUTPUT_BUCKET = var.output_bucket_id # Reference the output bucket
    }
  }
}




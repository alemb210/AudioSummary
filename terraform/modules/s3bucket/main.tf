resource "aws_s3_bucket" "bucket" {
  bucket = var.s3_bucket_name
  
}

#Declare an event that triggers a lambda function
resource "aws_s3_bucket_notification" "bucket_event" {
  #Allow for the definition of no events (website bucket case)
  count = length(var.events_trigger_lambda) > 0 ? 1 : 0 

  bucket = aws_s3_bucket.bucket.id
  
  lambda_function {
    lambda_function_arn = var.lambda_function_arn
    events              = var.events_trigger_lambda
  }

  depends_on = [
    var.lambda_permission_id,
    var.lambda_function_arn,
    aws_s3_bucket.bucket
  ]
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.bucket.id

  policy = var.s3_bucket_policy

  depends_on = [
    aws_s3_bucket.bucket
  ]
}

resource "aws_s3_bucket_lifecycle_configuration" "ttl" {
  count  = var.ttl_days > 0 ? 1 : 0 #Only create ttl config if ttl_days > 0
  bucket = aws_s3_bucket.bucket.id

  rule {
    id = "auto-delete-after-${var.ttl_days}-days"

    filter {
      prefix = ""
    }

    expiration {
      days = var.ttl_days
    }

    status = "Enabled"
  }
}



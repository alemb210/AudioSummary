resource "aws_cloudfront_origin_access_control" "oac" {
  name                              = "${var.s3_bucket_name}-oac"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "cdn" {
  enabled             = true
  default_root_object = var.default_root_object

  origin {
    domain_name              = var.s3_bucket_regional_domain_name
    origin_id                = "S3-${var.s3_bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.oac.id
  }

  default_cache_behavior {
    target_origin_id       = "S3-${var.s3_bucket_name}"
    viewer_protocol_policy = var.viewer_protocol_policy

    allowed_methods = var.allowed_methods
    cached_methods  = var.cached_methods
    compress        = var.compress
    min_ttl         = var.min_ttl
    default_ttl     = var.default_ttl
    max_ttl         = var.max_ttl

    forwarded_values { #defaults, required configuration
      query_string = false
      cookies {
        forward = "none"
      }
    }

  }



  #Hardcode as none for now, required configuration
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  #Hardcode as default for now, required configuration
  viewer_certificate {
    cloudfront_default_certificate = true
  }
}

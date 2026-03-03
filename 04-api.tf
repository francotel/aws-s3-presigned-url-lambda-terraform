locals {
  api_specific_tags = {
    Service   = "API"
    Component = "Upload"
    Exposure  = "Public"
  }
}

module "api_gateway" {
  source  = "terraform-aws-modules/apigateway-v2/aws"
  version = "6.1.0"

  name                  = "${var.project-name}-${var.env}-http-api"
  description           = "HTTP API for presigned URL upload"
  protocol_type         = "HTTP"
  create_certificate    = false
  create_stage          = true
  create_domain_name    = false
  create_domain_records = false

  cors_configuration = {
    allow_headers = ["Content-Type"]
    allow_methods = ["POST", "OPTIONS"]
    allow_origins = ["*"]
  }


  stage_access_log_settings = {
    create_log_group            = true
    log_group_retention_in_days = 14
    format = jsonencode({
      requestId   = "$context.requestId"
      ip          = "$context.identity.sourceIp"
      requestTime = "$context.requestTime"
      httpMethod  = "$context.httpMethod"
      routeKey    = "$context.routeKey"
      status      = "$context.status"
      error       = "$context.error.message"
    })
  }

  routes = {
    "POST /upload" = {
      integration = {
        uri                    = module.lambda_s3_presigned.lambda_function_arn
        payload_format_version = "2.0"
        timeout_milliseconds   = 10000
      }
    }
  }

  ################################
  # Tags
  ################################
  tags = merge(
    local.common_tags,
    local.api_specific_tags
  )

}

# output "api" {
#   value = module.api_gateway.integrations
# }
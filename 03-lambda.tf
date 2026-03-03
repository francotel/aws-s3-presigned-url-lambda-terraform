locals {
  lambda_specific_tags = {
    Service   = "Serverless"
    Component = "PresignedUrl"
    Runtime   = "NodeJS"
  }
}

data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "./src"
  output_path = "./lambda-function.zip"
  excludes = [
    "node_modules/.bin",
    "*.log",
    ".env"
  ]
}

module "lambda_s3_presigned" {
  source  = "terraform-aws-modules/lambda/aws"
  version = "8.7.0"

  function_name = "lambda-s3-presign-${var.project-name}"
  description   = "Generate pre-signed URL for secure S3 upload"

  handler = "index.handler"
  runtime = "nodejs24.x"


  ################################
  # Environment variables
  ################################
  environment_variables = {
    BUCKET_NAME        = module.s3_bucket.s3_bucket_id
    URL_EXPIRATION     = "300" # seconds
    REQUIRE_TLS        = "true"
    REQUIRE_ENCRYPTION = "true"
    DRY_RUN            = "false"
  }

  ################################
  # Deployment model (zip provided)
  ################################
  create_package         = false
  local_existing_package = data.archive_file.lambda_zip.output_path

  ignore_source_code_hash = false

  ################################
  # CloudWatch Logs
  ################################
  cloudwatch_logs_retention_in_days = 30
  cloudwatch_logs_log_group_class   = "STANDARD"
  cloudwatch_logs_skip_destroy      = false

  create_current_version_allowed_triggers = false

  ################################
  # Triggers (API Gateway)
  ################################
  allowed_triggers = {
    api_gateway = {
      principal    = "apigateway.amazonaws.com"
      statement_id = "AllowExecutionFromAPIGateway"
    }
  }

  ################################
  # IAM inline policies
  ################################
  attach_policy_statements = true

  policy_statements = {
    s3_presign = {
      effect = "Allow"
      actions = [
        "s3:PutObject",
        "s3:GetObject"
      ]
      resources = [
        "${module.s3_bucket.s3_bucket_arn}/*"
      ]
    }
  }

  ################################
  # Tags
  ################################
  tags = merge(
    local.common_tags,
    local.lambda_specific_tags
  )
}
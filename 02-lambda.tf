locals {
  lambda-specific-tags = {
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

  ################################
  # Function metadata
  ################################

  function_name = "lambda-s3-presign-${var.project-name}"
  description   = var.lambda-description

  handler = var.lambda-handler
  runtime = var.lambda-runtime

  ################################
  # Performance configuration
  ################################

  memory_size = var.lambda-memory-size
  timeout     = var.lambda-timeout

  architectures = ["arm64"]

  ################################
  # Observability
  ################################

  tracing_mode = var.lambda-xray-tracing-enabled ? "Active" : "PassThrough"

  ################################
  # Environment variables
  ################################

  environment_variables = {
    BUCKET_NAME     = module.s3_bucket.s3_bucket_id
    URL_EXPIRATION  = var.lambda-url-expiration
    AWS_REGION_NAME = var.aws-region
  }

  ################################
  # Deployment model
  ################################

  create_package          = false
  local_existing_package  = data.archive_file.lambda_zip.output_path
  ignore_source_code_hash = false

  ################################
  # CloudWatch Logs
  ################################

  cloudwatch_logs_retention_in_days = var.lambda-log-retention-days
  cloudwatch_logs_log_group_class   = "STANDARD"
  cloudwatch_logs_skip_destroy      = false

  ################################
  # Concurrency protection
  ################################

  reserved_concurrent_executions = var.lambda-reserved-concurrency

  create_current_version_allowed_triggers = false

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
    local.common-tags,
    local.lambda-specific-tags
  )
}
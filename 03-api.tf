locals {
  api-specific-tags = {
    Service   = "API"
    Component = "Upload"
    Exposure  = "Public"
  }
}

################################
# REST API
################################

resource "aws_api_gateway_rest_api" "api" {
  name        = "${var.project-name}-${var.env}-api"
  description = "REST API to generate S3 presigned URLs"

  ################################
  # Endpoint configuration
  ################################

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  ################################
  # Security best practices
  ################################

  # Disable default execute-api endpoint if using custom domain
  # disable_execute_api_endpoint = true

  tags = merge(
    local.common-tags,
    local.api-specific-tags
  )
}

################################
# API Resource
################################

resource "aws_api_gateway_resource" "presigned_url" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id
  path_part   = "presigned-url"
}

################################
# POST Method
################################

resource "aws_api_gateway_method" "post_presigned_url" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.presigned_url.id
  http_method   = "POST"
  authorization = "NONE"

  ################################
  # Security best practices
  ################################

  # request_validator_id = aws_api_gateway_request_validator.body.id
}

################################
# Lambda Integration
################################

resource "aws_api_gateway_integration" "lambda" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.presigned_url.id
  http_method = aws_api_gateway_method.post_presigned_url.http_method

  ################################
  # Lambda Proxy Integration
  ################################

  integration_http_method = "POST"
  type                    = "AWS_PROXY"

  uri = module.lambda_s3_presigned.lambda_function_invoke_arn

  ################################
  # Reliability configuration
  ################################

  timeout_milliseconds = var.api-timeout-ms
}

################################
# Lambda Permissions
################################

resource "aws_lambda_permission" "api_gateway" {

  ################################
  # Security best practices
  ################################

  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = module.lambda_s3_presigned.lambda_function_name
  principal     = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

################################
# CORS Support
################################

resource "aws_api_gateway_method" "options_presigned_url" {
  rest_api_id   = aws_api_gateway_rest_api.api.id
  resource_id   = aws_api_gateway_resource.presigned_url.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.presigned_url.id
  http_method = aws_api_gateway_method.options_presigned_url.http_method

  ################################
  # MOCK integration for CORS preflight
  ################################

  type = "MOCK"

  request_templates = {
    "application/json" = "{\"statusCode\": 200}"
  }

  timeout_milliseconds = var.api-timeout-ms
}

resource "aws_api_gateway_method_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.presigned_url.id
  http_method = aws_api_gateway_method.options_presigned_url.http_method
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Headers" = true
  }
}

resource "aws_api_gateway_integration_response" "options_200" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.presigned_url.id
  http_method = aws_api_gateway_method.options_presigned_url.http_method
  status_code = aws_api_gateway_method_response.options_200.status_code

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
    "method.response.header.Access-Control-Allow-Methods" = "'POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type'"
  }
}

################################
# Deployment
################################

resource "aws_api_gateway_deployment" "this" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  depends_on = [
    aws_api_gateway_integration.lambda,
    aws_api_gateway_integration.options
  ]
}

################################
# CloudWatch Logging
################################

resource "aws_iam_role" "api_gateway_cloudwatch_logs" {

  ################################
  # Security best practices
  ################################

  name = "api-gateway-cloudwatch-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "apigateway.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_logs" {

  ################################
  # AWS managed logging policy
  ################################

  role       = aws_iam_role.api_gateway_cloudwatch_logs.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_cloudwatch_log_group" "api_gw_logs" {

  ################################
  # Observability best practices
  ################################

  name              = "/aws/apigateway/${var.project-name}-${var.env}"
  retention_in_days = var.api-logs-retention-days

  tags = local.common-tags
}

resource "aws_api_gateway_account" "this" {
  count               = var.api-gateway-enable-cloudwatch-logs-role ? 1 : 0
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch_logs.arn
}

################################
# Stage configuration
################################

resource "aws_api_gateway_stage" "this" {
  rest_api_id          = aws_api_gateway_rest_api.api.id
  deployment_id        = aws_api_gateway_deployment.this.id
  stage_name           = var.env
  xray_tracing_enabled = var.xray-tracing-enabled

  ################################
  # Access logs configuration
  ################################

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gw_logs.arn

    format = jsonencode({
      requestId          = "$context.requestId"
      ip                 = "$context.identity.sourceIp"
      httpMethod         = "$context.httpMethod"
      resourcePath       = "$context.resourcePath"
      status             = "$context.status"
      responseLatency    = "$context.responseLatency"
      integrationLatency = "$context.integrationLatency"
      integrationStatus  = "$context.integration.status"
      integrationError   = "$context.integrationErrorMessage"
      errorMessage       = "$context.error.message"
      stage              = "$context.stage"
    })
  }

  depends_on = [
    aws_cloudwatch_log_group.api_gw_logs,
    aws_api_gateway_account.this
  ]

  tags = local.common-tags
}

################################
# Method settings
################################

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.this.stage_name
  method_path = "*/*"

  ################################
  # Observability best practices
  ################################

  settings {
    logging_level      = var.api-logging-level
    metrics_enabled    = true
    data_trace_enabled = var.api-enable-data-trace
  }
}

# output "api_gateway_logs" {
#   value = aws_cloudwatch_log_group.api_gw_logs.name
# }
# output "api_endpoint" {
#   value = aws_api_gateway_stage.this
# }

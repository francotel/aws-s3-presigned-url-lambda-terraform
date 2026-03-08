#################################################
# ENVIRONMENT CONFIGURATION
#################################################

variable "env" {
  description = "Environment name (dev, qa, prod)"
  type        = string
}

variable "aws-region" {
  description = "AWS region where resources will be deployed"
  type        = string
  default     = "us-east-1"
}

variable "project-name" {
  description = "Project or service name"
  type        = string
}

#################################################
# ORGANIZATION METADATA
#################################################

variable "owner" {
  description = "Owner or responsible team for the resources"
  type        = string
}

variable "cost" {
  description = "Cost center associated with the infrastructure"
  type        = string
}

variable "tf-version" {
  description = "Terraform version used for the project"
  type        = string
}

#################################################
# S3 BUCKET CONFIGURATION
#################################################

variable "s3-force-destroy" {
  description = "Allow bucket deletion even if objects exist"
  type        = bool
}

variable "s3-versioning-enabled" {
  description = "Enable versioning for the S3 bucket"
  type        = bool
}

variable "s3-encryption-algorithm" {
  description = "Server-side encryption algorithm used by S3"
  type        = string
}

# --- CORS configuration ---

variable "s3-cors-allowed-methods" {
  description = "Allowed HTTP methods for S3 CORS configuration"
  type        = list(string)
}

variable "s3-cors-allowed-origins" {
  description = "Allowed origins for S3 CORS configuration"
  type        = list(string)
}

variable "s3-cors-allowed-headers" {
  description = "Allowed headers for S3 CORS configuration"
  type        = list(string)
}

variable "s3-cors-expose-headers" {
  description = "Headers exposed in the S3 CORS response"
  type        = list(string)
}

variable "s3-cors-max-age-seconds" {
  description = "Time in seconds that browsers can cache the CORS response"
  type        = number
}

#################################################
# API GATEWAY CONFIGURATION
#################################################

variable "api-logs-retention-days" {
  description = "CloudWatch log retention period for API Gateway"
  type        = number
  default     = 14
}

variable "api-logging-level" {
  description = "Logging level for API Gateway (OFF | ERROR | INFO)"
  type        = string
  default     = "ERROR"
}

variable "api-enable-data-trace" {
  description = "Enable full request and response logging"
  type        = bool
  default     = false
}

variable "api-timeout-ms" {
  description = "Timeout for Lambda integration in milliseconds"
  type        = number
  default     = 1000
}

variable "xray-tracing-enabled" {
  description = "Enable XRAY logging"
  type        = bool
  default     = false
}

variable "api-gateway-enable-cloudwatch-logs-role" {
  description = "Enable API Gateway CloudWatch logs role configuration"
  type        = bool
  default     = true
}

#################################################
# LAMBDA CONFIGURATION
#################################################

variable "lambda-runtime" {
  description = "Runtime environment for the Lambda function"
  type        = string
}

variable "lambda-handler" {
  description = "Lambda function handler"
  type        = string
}

variable "lambda-description" {
  description = "Description of the Lambda function"
  type        = string
}

variable "lambda-url-expiration" {
  description = "Expiration time (seconds) for generated presigned URLs"
  type        = number
}

variable "lambda-log-retention-days" {
  description = "CloudWatch log retention period for Lambda"
  type        = number
}

variable "lambda-source-dir" {
  description = "Directory containing the Lambda source code"
  type        = string
}

variable "lambda-output-zip" {
  description = "Path where the Lambda zip package will be generated"
  type        = string
}

variable "lambda-timeout" {
  description = "Lambda timeout in seconds"
  type        = number
}

variable "lambda-memory-size" {
  description = "Lambda memory size in MB"
  type        = number
}

variable "lambda-xray-tracing-enabled" {
  description = "Enable AWS X-Ray tracing for Lambda"
  type        = bool
}

variable "lambda-reserved-concurrency" {
  description = "Reserved concurrency for Lambda function"
  type        = number
}
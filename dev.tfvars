#################################################
# ENVIRONMENT CONFIGURATION
#################################################

env          = "dev"
aws-region   = "us-east-2"
project-name = "secure-upload"

#################################################
# ORGANIZATION METADATA
#################################################

owner      = "platform-devops"
cost       = "banking-digital-channels"
tf-version = "1.11.2"

#################################################
# S3 BUCKET CONFIGURATION
#################################################

s3-force-destroy        = true
s3-versioning-enabled   = false
s3-encryption-algorithm = "AES256"

# CORS configuration
s3-cors-allowed-methods = [
  "GET",
  "PUT",
  "POST",
  "DELETE"
]

s3-cors-allowed-origins = [
  "*"
]

s3-cors-allowed-headers = [
  "*"
]

s3-cors-expose-headers = [
  "ETag"
]

s3-cors-max-age-seconds = 3000

#################################################
# API GATEWAY CONFIGURATION
#################################################

api-logs-retention-days                 = 7
api-logging-level                       = "INFO"
api-enable-data-trace                   = false
api-timeout-ms                          = 10000
api-gateway-enable-cloudwatch-logs-role = true

#################################################
# LAMBDA CONFIGURATION
#################################################

lambda-runtime     = "nodejs24.x"
lambda-handler     = "index.handler"
lambda-description = "Generate pre-signed URL for secure S3 upload"

lambda-url-expiration     = 300
lambda-log-retention-days = 14

lambda-timeout              = 5
lambda-memory-size          = 256
lambda-xray-tracing-enabled = false
lambda-reserved-concurrency = 1

lambda-source-dir = "./src"
lambda-output-zip = "./lambda-function.zip"
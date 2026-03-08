locals {
  s3-specific-tags = {
    Service         = "Storage"
    DataType        = "Logs"
    Compliance      = "Config"
    Confidentiality = "Internal"
  }
}

module "s3_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "5.10.0"

  bucket = "s3-${var.project-name}-uploads-${var.env}"

  force_destroy = var.s3-force-destroy

  ################################
  # Security best practices
  ################################
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  ################################
  # Versioning
  ################################
  versioning = {
    enabled = var.s3-versioning-enabled
  }

  ################################
  # Encryption
  ################################
  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = var.s3-encryption-algorithm
      }
    }
  }

  ################################
  # CORS
  ################################
  cors_rule = [
    {
      allowed_methods = var.s3-cors-allowed-methods
      allowed_origins = var.s3-cors-allowed-origins
      allowed_headers = var.s3-cors-allowed-headers
      expose_headers  = var.s3-cors-expose-headers
      max_age_seconds = var.s3-cors-max-age-seconds
    }
  ]

  ################################
  # Tags
  ################################
  tags = merge(
    local.common-tags,
    local.s3-specific-tags
  )
}
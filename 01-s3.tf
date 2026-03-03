locals {
  s3_specific_tags = {
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

  # Security best practices
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  control_object_ownership = true
  object_ownership         = "BucketOwnerEnforced"

  versioning = {
    enabled = false
  }

  server_side_encryption_configuration = {
    rule = {
      apply_server_side_encryption_by_default = {
        sse_algorithm = "AES256"
      }
    }
  }

  cors_rule = [
    {
      allowed_methods = ["GET", "PUT", "POST", "DELETE"]
      allowed_origins = ["*"]
      allowed_headers = ["*"]
      expose_headers  = ["ETag"]
      max_age_seconds = 3000
    }
  ]

  tags = merge(
    local.common_tags,
    local.s3_specific_tags
  )
}

output "s3" {
  value = module.s3_bucket
}
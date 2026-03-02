provider "aws" {
  # profile = var.profile # managment account local aws credential/config profile name
  region = var.aws-region
  # Common tags for all resources that accept tags
  default_tags {
    tags = {
      ManagedBy         = "Terraform"
      Env               = var.env
      Terraform-Version = var.tf-version
      Cost              = var.cost
      Owner             = var.owner
      Project           = var.project-name
    }
  }

  # Make it faster by skipping something
  skip_metadata_api_check     = true
  skip_region_validation      = true
  skip_credentials_validation = true
}
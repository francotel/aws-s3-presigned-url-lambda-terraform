data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  aws-account-id = data.aws_caller_identity.current.account_id
  aws-region     = data.aws_region.current.region
}

locals {
  common_tags = {
    Environment      = var.env
    Project          = var.project-name
    Owner            = var.owner
    CostCenter       = var.cost
    Terraform        = "true"
    TerraformVersion = var.tf-version
  }
}
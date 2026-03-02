data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  aws-account-id = data.aws_caller_identity.current.account_id
  aws-region     = data.aws_region.current.region
}
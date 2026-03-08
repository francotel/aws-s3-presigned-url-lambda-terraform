data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  aws-account-id = data.aws_caller_identity.current.account_id
  aws-region     = data.aws_region.current.region
}

locals {
  common-tags = {
    Environment      = var.env
    Project          = var.project-name
    Owner            = var.owner
    CostCenter       = var.cost
    Terraform        = "true"
    TerraformVersion = var.tf-version
  }
}

data "template_file" "client_html" {
  template = file("./client/index.html.tpl")
  vars = {
    api_gateway_url = "${aws_api_gateway_stage.this.invoke_url}/presigned-url"
  }
}

resource "local_file" "index_html" {
  content  = data.template_file.client_html.rendered
  filename = "./client/index.html"
}
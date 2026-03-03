data "aws_iam_policy_document" "lambda_s3_policy" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:GetObject"
    ]

    resources = [
      "${module.s3_bucket.s3_bucket_arn}/*"
    ]
  }
}

# module "lambda_iam_role" {
#   source  = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
#   version = "5.39.0"

#   create_role = true
#   role_name   = "${var.project-name}-lambda-role"

#   trusted_role_services = ["lambda.amazonaws.com"]

#   custom_role_policy_arns = [
#     "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
#   ]

#   inline_policy_statements = [
#     {
#       name   = "s3-access"
#       policy = data.aws_iam_policy_document.lambda_s3_policy.json
#     }
#   ]
# }
# --- Variables ---
variable "env" {
  type        = string
  description = "Environment name"
}

variable "project-name" {
  description = "Project Name or service"
  type        = string
}

variable "aws-region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

variable "owner" {
  description = "Owner Name or service"
  type        = string
}

variable "cost" {
  description = "Center of cost"
  type        = string
}

variable "tf-version" {
  description = "Terraform version that used for the project"
  type        = string
}

variable "s3-force-destroy" {
  description = "Delete Bucket"
  default     = true
}
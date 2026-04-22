variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "secondary_region" {
  description = "Secondary region"
  type        = string
}

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "iam_role_terraform_execution_arn" {
  description = "IAM role terraform execution ARN"
  type        = string
}

variable "iam_role_replication_id" {
  description = "IAM role for S3 bucket replication ID"
  type        = string
}

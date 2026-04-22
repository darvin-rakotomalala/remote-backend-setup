variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "current_region" {
  description = "Current region name"
  type        = string
}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "cloudtrail_kms_key_arn" {
  description = "KMS key ID for cloudtrail encryption ARN"
  type        = string
}

variable "terraform_state_log_group_arn" {
  description = "CloudWatch Terraform state log group ARN"
  type        = string
}

variable "iam_role_cloudtrail_logs_arn" {
  description = "IAM role for cloudtrail logs arn"
  type        = string
}

variable "bucket_terraform_state_arn" {
  description = "S3 bucket for Terraform state ARN"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
}

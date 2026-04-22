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

variable "github_org" {
  description = "GitHub organization"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository"
  type        = string
}

variable "bucket_terraform_state_arn" {
  description = "S3 bucket for Terraform state ARN"
  type        = string
}

variable "bucket_terraform_state_id" {
  description = "S3 bucket for Terraform state ID"
  type        = string
}

variable "bucket_state_backup_replica_arn" {
  description = "S3 bucket for Terraform state backup replication ARN"
  type        = string
}

variable "terraform_state_log_group_arn" {
  description = "CloudWatch Terraform state log group ARN"
  type        = string
}

variable "terraform_state_kms_key_arn" {
  description = "KMS key ID for state encryption ARN"
  type        = string
}

variable "replication_state_key_kms_key_arn" {
  description = "KMS key ID for replication state encryption ARN"
  type        = string
}

variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "secondary_region" {
  description = "Secondary region"
  type        = string
}

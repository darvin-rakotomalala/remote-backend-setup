variable "secondary_region" {
  description = "Secondary region"
  type        = string
}

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "backup_policy" {
  description = "Backup policy"
  type        = bool
  default     = true
}

variable "current_account_id" {
  description = "Current account ID"
  type        = string
}

variable "terraform_state_kms_key_arn" {
  description = "KMS key ID for state encryption ARN"
  type        = string
}

variable "dynamodb_replica_kms_key_arn" {
  description = "KMS key ID for dynamodb table replica encryption ARN"
  type        = string
}

variable "secondary_region" {
  description = "Secondary region"
  type        = string
}

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
}

variable "common_tags" {}

variable "dynamodb_table_terraform_locks_id" {
  description = "DynamoDB table name for state locking ID"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
}

variable "sns_terraform_state_alerts_arn" {
  description = "SNS topic for terraform state ARN"
  type        = string
}

variable "bucket_terraform_state_id" {
  description = "S3 bucket for Terraform state ID"
  type        = string
}

variable "bucket_state_backup_replica_id" {
  description = "S3 bucket for Terraform state backup replication ID"
  type        = string
}

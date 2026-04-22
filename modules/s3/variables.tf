variable "secondary_region" {
  description = "Secondary region"
  type        = string
}

variable "environment" {
  description = "Environment name"
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

variable "enable_versioning" {
  description = "Enable S3 versioning for state file history"
  type        = bool
  default     = true
}

variable "standard_ia" {
  description = "Number of days to standard_ia"
  type        = number
  default     = 30
}

variable "glacier_ir" {
  description = "Number of days to glacier_ir"
  type        = number
  default     = 90
}

variable "deep_archive" {
  description = "Number of days to deep archive"
  type        = number
  default     = 180
}

variable "noncurrent_days" {
  description = "Number of days to noncurrent"
  type        = number
  default     = 90
}

variable "days_after_initiation" {
  description = "Number of days after initiation"
  type        = number
  default     = 7
}

variable "noncurrent_version_expiration" {
  description = "Number of days noncurrent_version_expiration"
  type        = number
  default     = 120
}

variable "terraform_state_kms_key_arn" {
  description = "KMS key ID for state encryption ARN"
  type        = string
}

variable "sns_s3_event_notification_topic_arn" {
  description = "SNS s3 event notification topic ARN"
  type        = string
}

variable "iam_role_replication_arn" {
  description = "IAM role for S3 bucket replication ARN"
  type        = string
}

variable "replication_state_key_kms_key_arn" {
  description = "KMS key ID for replication state encryption ARN"
  type        = string
}

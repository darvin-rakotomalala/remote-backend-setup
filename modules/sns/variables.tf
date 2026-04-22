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

variable "email_subscriptions" {
  description = "A list of email addresses to subscribe to the SNS topic"
  type        = list(string)
}

variable "bucket_terraform_state_arn" {
  description = "S3 bucket for Terraform state ARN"
  type        = string
}

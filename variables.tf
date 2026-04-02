variable "primary_region" {
  description = "Primary region"
  type        = string
}

variable "secondary_region" {
  description = "Secondary region"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "project_name" {
  description = "Project name"
  type        = string
}

variable "team_name" {
  description = "Team name"
  type        = string
}

variable "cost_center" {
  description = "Cost center"
  type        = string
}

variable "compliance" {
  description = "Compliance"
  type        = string
}

variable "naming_prefix" {
  description = "Naming prefix"
  type        = string
  default     = ""
}

variable "github_org" {
  description = "GitHub organization"
  type        = string
}

variable "email_subscriptions" {
  description = "A list of email addresses to subscribe to the SNS topic"
  type        = list(string)
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
  default     = 90
}


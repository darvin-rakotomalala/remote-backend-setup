output "state_bucket_name" {
  description = "S3 bucket name for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "s3_bucket_arn" {
  description = "ARN of the S3 bucket"
  value       = aws_s3_bucket.terraform_state.arn
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "kms_key_id" {
  description = "KMS key ID for state encryption"
  value       = aws_kms_key.terraform_state.id
}

output "terraform_execution_role_arn" {
  description = "IAM role ARN for Terraform execution"
  value       = aws_iam_role.terraform_execution.arn
  sensitive   = true
}

output "terraform_execution_role_name" {
  description = "IAM role name for Terraform execution"
  value       = aws_iam_role.terraform_execution.name
}

output "backend_config" {
  description = "Backend configuration to use in other projects"
  value       = <<-EOT
  terraform {
    backend "s3" {
      bucket         = "${aws_s3_bucket.terraform_state.id}"
      key            = "${var.environment}/infrastructure/terraform.tfstate"
      region         = "${var.primary_region}"
      encrypt        = true
      kms_key_id     = "${aws_kms_key.terraform_state.id}"
      dynamodb_table = "${aws_dynamodb_table.terraform_locks.name}"
    }
  }
  EOT
}

output "destination_bucket" {
  description = "S3 bucket replica destination"
  value       = aws_s3_bucket.state_backup_replica.id
}

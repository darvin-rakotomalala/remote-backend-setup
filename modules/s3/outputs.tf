output "bucket_terraform_state_name" {
  description = "S3 bucket name for Terraform state"
  value       = aws_s3_bucket.terraform_state.id
}

output "bucket_replication_destination_id" {
  description = "S3 bucket replica destination"
  value       = aws_s3_bucket.state_backup_replica.id
}

output "bucket_state_backup_replica_arn" {
  description = "S3 bucket for Terraform state backup replication ARN"
  value       = aws_s3_bucket.state_backup_replica.arn
}

output "bucket_state_backup_replica_id" {
  description = "S3 bucket for Terraform state backup replication ID"
  value       = aws_s3_bucket.state_backup_replica.id
}

output "bucket_terraform_state_arn" {
  description = "S3 bucket for Terraform state ARN"
  value       = aws_s3_bucket.terraform_state.arn
}

output "bucket_terraform_state_id" {
  description = "S3 bucket for Terraform state ID"
  value       = aws_s3_bucket.terraform_state.id
}

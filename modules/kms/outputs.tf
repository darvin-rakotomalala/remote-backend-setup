output "terraform_state_kms_key_id" {
  description = "KMS key ID for state encryption"
  value       = aws_kms_key.terraform_state.id
}

output "terraform_state_kms_key_arn" {
  description = "KMS key ID for state encryption ARN"
  value       = aws_kms_key.terraform_state.arn
}

output "replication_state_key_kms_key_id" {
  description = "KMS key ID for replication state encryption"
  value       = aws_kms_key.replication_state_key.id
}

output "replication_state_key_kms_key_arn" {
  description = "KMS key ID for replication state encryption ARN"
  value       = aws_kms_key.replication_state_key.arn
}

output "cloudtrail_kms_key_id" {
  description = "KMS key ID for cloudtrail encryption ID"
  value       = aws_kms_key.cloudtrail.id
}

output "cloudtrail_kms_key_arn" {
  description = "KMS key ID for cloudtrail encryption ARN"
  value       = aws_kms_key.cloudtrail.arn
}

output "dynamodb_replica_kms_key_id" {
  description = "KMS key ID for dynamodb table replica encryption ID"
  value       = aws_kms_key.dynamodb_replica.id
}

output "dynamodb_replica_kms_key_arn" {
  description = "KMS key ID for dynamodb table replica encryption ARN"
  value       = aws_kms_key.dynamodb_replica.arn
}

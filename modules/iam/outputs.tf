output "iam_role_terraform_execution_arn" {
  description = "IAM role terraform execution ARN"
  value       = aws_iam_role.terraform_execution.arn
}

output "iam_role_replication_arn" {
  description = "IAM role replication ARN"
  value       = aws_iam_role.replication.arn
}

output "iam_role_replication_id" {
  description = "IAM role replication ID"
  value       = aws_iam_role.replication.id
}

output "iam_role_cloudtrail_logs_arn" {
  description = "IAM role for cloudtrail logs arn"
  value       = aws_iam_role.cloudtrail_logs.arn
}

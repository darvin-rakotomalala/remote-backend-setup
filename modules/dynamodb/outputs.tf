output "dynamodb_table_name" {
  description = "DynamoDB table name for state locking"
  value       = aws_dynamodb_table.terraform_locks.name
}

output "dynamodb_table_terraform_locks_id" {
  description = "DynamoDB table name for state locking ID"
  value       = aws_dynamodb_table.terraform_locks.id
}

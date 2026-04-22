output "terraform_state_log_group_arn" {
  description = "CloudWatch Terraform state log group ARN"
  value       = aws_cloudwatch_log_group.terraform_state_log_group.arn
}

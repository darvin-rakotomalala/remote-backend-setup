output "sns_s3_event_notification_topic_arn" {
  description = "SNS s3 event notification topic ARN"
  value       = aws_sns_topic.s3_event_notification_topic.arn
}

output "sns_terraform_state_alerts_arn" {
  description = "SNS topic for terraform state ARN"
  value       = aws_sns_topic.terraform_state_alerts.arn
}

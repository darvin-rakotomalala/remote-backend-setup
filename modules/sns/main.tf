####################################################
# SNS Topic for notifications/alerts
####################################################
resource "aws_sns_topic" "terraform_state_alerts" {
  name = "${var.naming_prefix}-terraform-state-alerts"

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-terraform-state-alerts"
    Type    = "notifications"
    Purpose = "notifications-alerts"
  })
}

resource "aws_sns_topic_subscription" "terraform_state_email_subscriptions" {
  for_each  = toset(var.email_subscriptions)
  topic_arn = aws_sns_topic.terraform_state_alerts.arn
  protocol  = "email"
  endpoint  = each.value
}

####################################################
# Create an SNS topic with a email subscription
####################################################
resource "aws_sns_topic" "s3_event_notification_topic" {
  name   = "${var.naming_prefix}-s3-event-notification-topic"
  policy = <<POLICY
    {
      "Version":"2012-10-17",
      "Statement":[{
        "Effect": "Allow",
        "Principal": { "Service": "s3.amazonaws.com" },
        "Action": "SNS:Publish",
        "Resource": "arn:aws:sns:${var.current_region}:${var.current_account_id}:${var.naming_prefix}-s3-event-notification-topic",
        "Condition":{
            "StringEquals":{"aws:SourceAccount":"${var.current_account_id}"},
            "ArnLike":{"aws:SourceArn":"${var.bucket_terraform_state_arn}"}
        }
      }]
    }
POLICY

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-s3-event-notification-topic"
    Type    = "notifications"
    Purpose = "s3-event-notification"
  })
}

resource "aws_sns_topic_subscription" "s3_event_email_subscriptions" {
  for_each  = toset(var.email_subscriptions)
  topic_arn = aws_sns_topic.s3_event_notification_topic.arn
  protocol  = "email"
  endpoint  = each.value
}

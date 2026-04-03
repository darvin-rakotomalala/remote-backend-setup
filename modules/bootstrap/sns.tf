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

locals {
  topics = {
    terraform_state_alerts      = aws_sns_topic.terraform_state_alerts.arn
    s3_event_notification_topic = aws_sns_topic.s3-event-notification-topic.arn
  }

  topic_email_subscriptions = {
    for pair in setproduct(keys(local.topics), var.email_subscriptions) :
    "${pair[0]}-${pair[1]}" => {
      topic_arn = local.topics[pair[0]]
      email     = pair[1]
    }
  }
}

resource "aws_sns_topic_subscription" "state_backup_email" {
  for_each  = local.topic_email_subscriptions
  topic_arn = each.value["topic_arn"]
  protocol  = "email"
  endpoint  = each.value["email"]
}

####################################################
# Create an SNS topic with a email subscription
####################################################
resource "aws_sns_topic" "s3-event-notification-topic" {
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
            "ArnLike":{"aws:SourceArn":"${aws_s3_bucket.terraform_state.arn}"}
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

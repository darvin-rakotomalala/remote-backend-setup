#####################################################
# CloudWatch for monitoring
#####################################################

# Send CloudTrail events to CloudWatch Logs for real-time monitoring and alerting
resource "aws_cloudwatch_log_group" "terraform_state_log_group" {
  name              = "/aws/cloudtrail/${var.naming_prefix}-terraform-state-file-trail"
  retention_in_days = 7 # adjust based on compliance needs
  # retention_in_days = 365

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-terraform-state-log"
    Type    = "terraform-state-log-group"
    Purpose = "cloudtrail-logging"
  })
}

# Monitor Lock Table - CloudWatch Metric Alarm
resource "aws_cloudwatch_metric_alarm" "long_held_lock_alarm" {
  alarm_name          = "${var.naming_prefix}-LongHeldTerraformLockAlarm"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 12 # 1 hour (12 × 5 minutes)
  metric_name         = "ItemCount"
  namespace           = "AWS/DynamoDB"
  period              = 300 # 5 minutes
  statistic           = "Maximum"
  threshold           = 1
  alarm_description   = "Alert when Terraform locks are held too long"
  treat_missing_data  = "notBreaching"

  dimensions = {
    TableName = var.dynamodb_table_terraform_locks_id
  }

  alarm_actions = [var.sns_terraform_state_alerts_arn]

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-long-held-terraform-lock-alarm"
    Type    = "terraform-lock-alarm"
    Purpose = "terraform-lock-alarm"
  })
}

# Monitoring Global Tables
# Alarm for high replication latency
resource "aws_cloudwatch_metric_alarm" "replication_latency" {
  alarm_name          = "${var.naming_prefix}-dynamodb-table-replication-latency"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "ReplicationLatency"
  namespace           = "AWS/DynamoDB"
  period              = 300 # 5 minutes
  statistic           = "Average"
  threshold           = 5000 # 5 seconds
  alarm_description   = "DynamoDB global table replication latency is above 5 seconds"

  dimensions = {
    TableName       = var.dynamodb_table_name
    ReceivingRegion = var.secondary_region
  }

  alarm_actions = [var.sns_terraform_state_alerts_arn]

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-dynamodb-table-replication-latency"
    Type    = "replication-latency"
    Purpose = "dynamodb-table-replication-latency"
  })
}

# Alert when unusual Terraform state access detected
resource "aws_cloudwatch_metric_alarm" "excessive_state_access" {
  alarm_name          = "${var.naming_prefix}-excessive-terraform-state-access"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "TerraformStateAccess"
  namespace           = "Security"
  period              = 300
  statistic           = "Sum"
  threshold           = 100 # > 100 accesses in 5 minutes
  alarm_description   = "Unusual Terraform state access detected"
  alarm_actions       = [var.sns_terraform_state_alerts_arn]

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-excessive-terraform-state-access"
    Type    = "terraform-state-access"
    Purpose = "security"
  })
}

# CloudWatch alarm for state file modifications
resource "aws_cloudwatch_metric_alarm" "state_modification" {
  alarm_name          = "${var.naming_prefix}-terraform-state-modified"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "PutObject"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alert when Terraform state is modified"

  dimensions = {
    BucketName = var.bucket_terraform_state_id
    FilterId   = "AllObjects"
  }

  alarm_actions = [var.sns_terraform_state_alerts_arn]

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-terraform-state-modified"
    Type    = "auditing"
    Purpose = "terraform-state-modified"
  })
}

# Alert on state file access
resource "aws_cloudwatch_log_metric_filter" "state_access" {
  name           = "${var.naming_prefix}-terraform-state-access"
  pattern        = "{ $.requestParameters.bucketName = \"${var.bucket_terraform_state_id}\" }"
  log_group_name = aws_cloudwatch_log_group.terraform_state_log_group.name

  metric_transformation {
    name          = "TerraformStateAccessCount"
    namespace     = "Custom/Terraform"
    value         = "1"
    default_value = "0"
    unit          = "Count"
  }
}

# Alert when more than 5 access over 5 minute period
resource "aws_cloudwatch_metric_alarm" "state_access" {
  alarm_name          = "${var.naming_prefix}-terraform-state-file-access"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  period              = 300 # 5 minutes
  evaluation_periods  = 1
  metric_name         = aws_cloudwatch_log_metric_filter.state_access.metric_transformation[0].name
  namespace           = "Terraform/StateFile"
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "More than 5 access over 5 minute period"
  unit                = "Count"
  alarm_actions       = [var.sns_terraform_state_alerts_arn]

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-terraform-state-file-access"
    Type    = "auditing"
    Purpose = "auditing-terraform-state-file-access"
  })
}

# Alert when state backups are stale
resource "aws_cloudwatch_metric_alarm" "state_backup_stale" {
  alarm_name          = "${var.naming_prefix}-terraform-state-backup-stale"
  comparison_operator = "LessThanThreshold"
  evaluation_periods  = 1
  metric_name         = "NumberOfObjects"
  namespace           = "AWS/S3"
  period              = 86400 # Check daily
  statistic           = "Average"
  threshold           = 1
  alarm_description   = "No new state file versions in the last 24 hours"

  dimensions = {
    BucketName  = var.bucket_terraform_state_id
    StorageType = "AllStorageTypes"
  }

  alarm_actions = [var.sns_terraform_state_alerts_arn]

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-terraform-state-backup-stale"
    Type    = "auditing"
    Purpose = "terraform-state-backup-stale"
  })
}

# CloudWatch alarm for replication lag
resource "aws_cloudwatch_metric_alarm" "replication_lag" {
  alarm_name          = "${var.naming_prefix}-terraform-state-replication-lag"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "ReplicationLatency"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Maximum"
  threshold           = 900 # 15 minutes
  alarm_description   = "Terraform state replication is lagging"

  dimensions = {
    SourceBucket      = var.bucket_terraform_state_id
    DestinationBucket = var.bucket_state_backup_replica_id
    RuleId            = "replicate-all-state"
  }

  alarm_actions = [var.sns_terraform_state_alerts_arn]

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-terraform-state-replication-lag"
    Type    = "backup"
    Purpose = "terraform-state-replication"
  })
}

# Alarm when replication is failing
resource "aws_cloudwatch_metric_alarm" "replication_failure" {
  alarm_name          = "s3-replication-failure"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 3
  metric_name         = "OperationFailedReplication"
  namespace           = "AWS/S3"
  period              = 300
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Alarm when replication is failing"

  dimensions = {
    SourceBucket      = var.bucket_terraform_state_id
    DestinationBucket = var.bucket_state_backup_replica_id
    RuleId            = "replicate-all"
  }
  alarm_actions = [var.sns_terraform_state_alerts_arn]

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-s3-replication-failure"
    Type    = "replication"
    Purpose = "s3-replication-failure"
  })
}

##########################################################
# CloudTrail captures all OIDC authentication attempts
##########################################################
resource "aws_cloudwatch_log_group" "oidc_events" {
  name              = "/aws/cloudtrail/${var.naming_prefix}-github-oidc"
  retention_in_days = 7 # adjust based on compliance needs
  # retention_in_days = 90

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-github-oidc"
    Type    = "deployement"
    Purpose = "github-oidc-logs"
  })
}

# CloudWatch metric filter for failed authentication attempts
resource "aws_cloudwatch_log_metric_filter" "oidc_failures" {
  name           = "${var.naming_prefix}-github-oidc-auth-failures"
  pattern        = "{ $.eventName = AssumeRoleWithWebIdentity && $.errorCode = * }"
  log_group_name = aws_cloudwatch_log_group.oidc_events.name

  metric_transformation {
    name      = "OIDCAuthFailures"
    namespace = "Security/OIDC"
    value     = "1"
  }
}

# Alarm on authentication failures
resource "aws_cloudwatch_metric_alarm" "oidc_failures_alarm" {
  alarm_name          = "${var.naming_prefix}-github-oidc-auth-failures"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "OIDCAuthFailures"
  namespace           = "Security/OIDC"
  period              = 300
  statistic           = "Sum"
  threshold           = 5
  alarm_description   = "Multiple failed OIDC authentication attempts detected"
  alarm_actions       = [var.sns_terraform_state_alerts_arn]

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-github-oidc-auth-failures"
    Type    = "security"
    Purpose = "github-oidc-auth-failures"
  })
}

##########################################################
# Security Alerts with CloudWatch Metric Filters
##########################################################

# Metric filter for unauthorized API calls
resource "aws_cloudwatch_log_metric_filter" "unauthorized_api_calls" {
  name           = "${var.naming_prefix}-unauthorized-api-calls"
  pattern        = "{ ($.errorCode = \"*UnauthorizedAccess\") || ($.errorCode = \"AccessDenied*\") }"
  log_group_name = aws_cloudwatch_log_group.terraform_state_log_group.name

  metric_transformation {
    name      = "UnauthorizedAPICalls"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

# Alarm for too many unauthorized calls
resource "aws_cloudwatch_metric_alarm" "unauthorized_api_calls" {
  alarm_name          = "${var.naming_prefix}-unauthorized-api-calls"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "UnauthorizedAPICalls"
  namespace           = "CloudTrailMetrics"
  period              = 300
  statistic           = "Sum"
  threshold           = 10
  alarm_description   = "Alert when unauthorized API calls exceed threshold"
  alarm_actions       = [var.sns_terraform_state_alerts_arn]

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-unauthorized-api-calls"
    Type    = "security"
    Purpose = "unauthorized-api-calls"
  })
}

# Metric filter for root account usage
resource "aws_cloudwatch_log_metric_filter" "root_account_usage" {
  name           = "${var.naming_prefix}-root-account-usage"
  pattern        = "{ $.userIdentity.type = \"Root\" && $.userIdentity.invokedBy NOT EXISTS && $.eventType != \"AwsServiceEvent\" }"
  log_group_name = aws_cloudwatch_log_group.terraform_state_log_group.name

  metric_transformation {
    name      = "RootAccountUsage"
    namespace = "CloudTrailMetrics"
    value     = "1"
  }
}

resource "aws_cloudwatch_metric_alarm" "root_usage" {
  alarm_name          = "${var.naming_prefix}-root-account-usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "RootAccountUsage"
  namespace           = "CloudTrailMetrics"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Alert when root account is used"
  alarm_actions       = [var.sns_terraform_state_alerts_arn]

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-root-account-usage"
    Type    = "security"
    Purpose = "root-account-usage"
  })
}

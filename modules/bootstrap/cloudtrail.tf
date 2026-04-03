#####################################################################
# Audit State Access with CloudTrail
#####################################################################

# S3 bucket for audit logs with its own retention policy
resource "aws_s3_bucket" "cloudtrail_logs" {
  bucket        = "${var.naming_prefix}-terraform-audit-logs"
  force_destroy = true # for Non-Production Buckets
  # force_destroy = var.environment != "production"

  lifecycle {
    prevent_destroy = false # set true for prod
  }

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-terraform-audit-logs"
    Type    = "audit-logs"
    Purpose = "cloudtrail-logging"
  })
}

# Enable versioning on the audit bucket
resource "aws_s3_bucket_versioning" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable server-side encryption with KMS
resource "aws_s3_bucket_server_side_encryption_configuration" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.cloudtrail.arn
    }
    bucket_key_enabled = true
  }
}

# Block all public access
resource "aws_s3_bucket_public_access_block" "cloudtrail_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle rules to manage log retention
resource "aws_s3_bucket_lifecycle_configuration" "audit_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  rule {
    id     = "retain-audit-logs"
    status = "Enabled"

    # Move to Glacier after 90 days for cost savings
    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # Delete after 365 days (adjust based on compliance needs)
    expiration {
      days = 365
    }
  }
}

# Centralize Audit Logs - Send CloudTrail events to CloudWatch Logs for centralized querying
# Create a CloudTrail trail specifically for Terraform state auditing
resource "aws_cloudtrail" "cloudtrail_logs" {
  name                          = "${var.naming_prefix}-terraform-state-audit"
  s3_bucket_name                = aws_s3_bucket.cloudtrail_logs.id
  kms_key_id                    = aws_kms_key.cloudtrail.arn
  enable_log_file_validation    = true # relates digest files so you can verify log integrity
  include_global_service_events = true # captures IAM, STS, and CloudFront events
  is_multi_region_trail         = true # captures events from all AWS regions
  enable_logging                = true

  depends_on = [aws_s3_bucket_policy.cloudtrail_audit_logs]

  # Send logs to CloudWatch for real-time analysis
  cloud_watch_logs_group_arn = "${aws_cloudwatch_log_group.terraform_state_log_group.arn}:*"
  cloud_watch_logs_role_arn  = aws_iam_role.cloudtrail_logs.arn

  # Capture data events for the state bucket
  # Log all management events
  event_selector {
    read_write_type           = "All"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${aws_s3_bucket.terraform_state.arn}/"]
    }
  }

  # Also capture DynamoDB events for lock operations
  event_selector {
    read_write_type           = "All"
    include_management_events = false

    data_resource {
      type   = "AWS::DynamoDB::Table"
      values = ["arn:aws:dynamodb:${var.current_region}:${var.current_account_id}:table/${aws_dynamodb_table.terraform_locks.name}"]
    }
  }

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-terraform-state-trail"
    Type    = "terraform-state-auditing"
    Purpose = "security-auditing"
  })
}

#############################################
# S3 bucket for state files
#############################################
resource "aws_s3_bucket" "terraform_state" {
  bucket        = "${var.naming_prefix}-terraform-state-69127"
  force_destroy = true # set false for prod
  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = false # set true for prod
  }

  tags = merge(var.common_tags, {
    Name         = "${var.naming_prefix}-terraform-state"
    Type         = "terraform-state"
    Purpose      = "backend"
    BackupPolicy = var.backup_policy
  })
}

# Enable versioning (critical for state recovery)
# Enable versioning to keep state history
resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }
    bucket_key_enabled = true
  }
}

# Block all public access (CRITICAL SECURITY)
resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Lifecycle Policy for Cost Optimization
resource "aws_s3_bucket_lifecycle_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    id     = "transition-to-ia"
    status = "Enabled"

    transition {
      days          = var.standard_ia
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.glacier_ir
      storage_class = "GLACIER_IR"
    }

    transition {
      days          = var.deep_archive
      storage_class = "DEEP_ARCHIVE"
    }

    noncurrent_version_transition {
      noncurrent_days = var.noncurrent_days
      storage_class   = "STANDARD_IA"
    }

    # Keep old versions for 90 days before cleaning up
    noncurrent_version_expiration {
      noncurrent_days = var.noncurrent_version_expiration
    }
  }

  rule {
    id     = "delete-incomplete-uploads"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = var.days_after_initiation
    }
  }

  rule {
    id     = "expire-old-delete-markers"
    status = "Enabled"

    expiration {
      expired_object_delete_marker = true
    }
  }
}

# Logs bucket
resource "aws_s3_bucket" "access_logs" {
  bucket        = "${var.naming_prefix}-terraform-logs-69127"
  force_destroy = true # set false for prod
  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = false # set true for prod
  }

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-logs-bucket"
    Type    = "logs bucket"
    Purpose = "s3-access-logging"
  })
}

# S3 Access Logging - Enable access logging on the state bucket
resource "aws_s3_bucket_logging" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  target_bucket = aws_s3_bucket.access_logs.id
  target_prefix = "terraform-state-access-logs/"
}

# S3 Access Logging enable encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.terraform_state.arn
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "logs" {
  bucket = aws_s3_bucket.access_logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    expiration {
      days = 90
    }
  }
}

####################################################
# S3 Event to SNS Notifications for ObjectCreated and ObjectRemoved
####################################################
resource "aws_s3_bucket_notification" "bucket-notification" {
  bucket = aws_s3_bucket.terraform_state.id
  topic {
    topic_arn     = aws_sns_topic.s3-event-notification-topic.arn
    events        = ["s3:ObjectCreated:*", "s3:ObjectRemoved:*"] # You can specify the events you are interested in
    filter_prefix = "${var.naming_prefix}/"
    filter_suffix = "terraform.tfstate"
  }
}

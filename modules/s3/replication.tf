terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.38.0"
    }
  }
}
####################################################################################
# State File Backup and Recovery - Cross-region state backup replication
# For critical production infrastructure, replicate state backups to another region
####################################################################################

# Secondary provider
provider "aws" {
  alias  = "us_west"
  region = var.secondary_region
}

resource "aws_s3_bucket" "state_backup_replica" {
  provider      = aws.us_west
  bucket        = "${var.naming_prefix}-terraform-state-data-replica-${random_string.bucket_suffix.result}"
  force_destroy = true # set false for prod
  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = false # set true for prod
  }

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-terraform-state-data-replica"
    Type    = "replication"
    Purpose = "terraform-state-backup-recovery"
  })
}

# Enable versioning to keep state history
resource "aws_s3_bucket_versioning" "state_backup_replica" {
  provider = aws.us_west
  bucket   = aws_s3_bucket.state_backup_replica.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# Replication configuration with encryption
resource "aws_s3_bucket_replication_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  role   = var.iam_role_replication_arn

  # Depends on versioning being enabled on both buckets
  depends_on = [
    aws_s3_bucket_versioning.terraform_state,
    aws_s3_bucket_versioning.state_backup_replica
  ]

  rule {
    id     = "replicate-all-state"
    status = "Enabled"

    filter {} # Empty filter = replicate everything, V2 schema

    # Replicate delete markers
    delete_marker_replication {
      status = "Enabled"
    }

    # Enable replication of KMS-encrypted objects
    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = aws_s3_bucket.state_backup_replica.arn
      storage_class = "STANDARD_IA"

      # Re-encrypt with the destination region's KMS key
      encryption_configuration {
        replica_kms_key_id = var.replication_state_key_kms_key_arn
      }
      /*
      # Enable Replication Time Control
      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }

      # Metrics for monitoring replication
      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }
      */
    }
  }
}

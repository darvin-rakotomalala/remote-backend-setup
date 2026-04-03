#################################################
# State File Backup and Recovery - Cross-region state backup replication
# For critical production infrastructure, replicate state backups to another region
#################################################

# Secondary provider
provider "aws" {
  alias  = "us_west"
  region = var.secondary_region
}

resource "aws_s3_bucket" "state_backup_replica" {
  provider      = aws.us_west
  bucket        = "${var.naming_prefix}-terraform-state-data-replica-69127"
  force_destroy = true # set false for prod
  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = false # set true for prod
  }

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-terraform-state-data-replica"
    Type    = "replication"
    Purpose = "backup-recovery"
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

# Replication Configuration - set up replication from primary to replica
resource "aws_s3_bucket_replication_configuration" "terraform_state" {
  depends_on = [
    aws_s3_bucket_versioning.terraform_state,
    aws_s3_bucket_versioning.state_backup_replica
  ]

  bucket = aws_s3_bucket.terraform_state.id
  role   = aws_iam_role.replication.arn

  rule {
    id     = "replicate-all-state"
    status = "Enabled"

    filter {}

    source_selection_criteria {
      sse_kms_encrypted_objects {
        status = "Enabled"
      }
    }

    destination {
      bucket        = aws_s3_bucket.state_backup_replica.arn
      storage_class = "STANDARD_IA"

      replication_time {
        status = "Enabled"
        time {
          minutes = 15
        }
      }

      metrics {
        status = "Enabled"
        event_threshold {
          minutes = 15
        }
      }

      # Replicate encrypted objects
      encryption_configuration {
        replica_kms_key_id = aws_kms_key.replication_state_key.arn
      }
    }

    delete_marker_replication {
      status = "Enabled"
    }
  }
}

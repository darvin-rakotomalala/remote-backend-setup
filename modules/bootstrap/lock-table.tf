#################################################
# DynamoDB table for state locking
# Global DynamoDB table for locking
#################################################
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.naming_prefix}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST" # On-demand is recommended for global tables
  hash_key     = "LockID"

  # Enable streams - required for global tables
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "LockID"
    type = "S"
  }

  # Point-in-time recovery
  point_in_time_recovery {
    enabled = true
  }

  # Prevent accidental deletion
  lifecycle {
    prevent_destroy = false # set true for prod
  }

  # Primary table KMS encryption
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.terraform_state.arn
  }

  replica {
    region_name            = var.secondary_region
    point_in_time_recovery = true
    kms_key_arn            = aws_kms_key.dynamodb_replica.arn # Custom CMK per replica
    propagate_tags         = true
  }

  tags = merge(var.common_tags, {
    Name         = "${var.naming_prefix}-terraform-locks-table"
    Type         = "terraform-locks-table"
    Purpose      = "terraform-state-locking"
    BackupPolicy = var.backup_policy
  })
}

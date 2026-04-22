#######################################################
# IAM Role for Replication
#######################################################
resource "aws_iam_role" "replication" {
  name = "${var.naming_prefix}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "s3.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-s3-replication-role"
    Type    = "role"
    Purpose = "s3-replication-role"
  })
}

# IAM policy granting replication permissions
resource "aws_iam_role_policy" "replication" {
  name = "${var.naming_prefix}-s3-replication-policy"
  role = aws_iam_role.replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = var.bucket_terraform_state_arn
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
          "s3:GetObjectVersion",
          "s3:GetObjectLegalHold",
          "s3:GetObjectRetention"
        ]
        Resource = "${var.bucket_terraform_state_arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${var.bucket_state_backup_replica_arn}/*"
      }
    ]
  })
}

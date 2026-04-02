################################################
# KMS key for state encryption
################################################
resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state encryption"
  deletion_window_in_days = 7 # adjust based on compliance needs
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.current_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Terraform service role"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.terraform_execution.arn
        }
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey",
          "kms:Encrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*"
        ]
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-terraform-state-encryption-key"
    Type    = "encryption"
    Purpose = "encryption-state-management"
  })
}

resource "aws_kms_alias" "terraform_state" {
  name          = "alias/${var.project_name}-terraform-state-${var.environment}"
  target_key_id = aws_kms_key.terraform_state.key_id
}

################################################
# KMS replication key for Terraform state encryption
################################################
resource "aws_kms_key" "replication_state_key" {
  provider                = aws.us_west
  description             = "KMS replication key for Terraform state encryption"
  deletion_window_in_days = 7 # adjust based on compliance needs
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.current_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-terraform-state-encryption-key"
    Type    = "Encryption"
    Purpose = "Encryption-replication-state-file"
  })
}

resource "aws_kms_alias" "replication_state_key" {
  provider      = aws.us_west
  name          = "alias/${var.project_name}-replication-state-key-${var.environment}"
  target_key_id = aws_kms_key.replication_state_key.key_id
}

################################################
# KMS key for encrypting CloudTrail logs
# Encrypting CloudTrail logs with a customer-managed KMS key gives
# you control over who can read the logs
################################################
resource "aws_kms_key" "cloudtrail" {
  description             = "KMS key for CloudTrail log encryption"
  deletion_window_in_days = 7 # adjust based on compliance needs
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # Allow root account full access
        Sid    = "EnableRootAccountPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.current_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        # Allow CloudTrail to encrypt logs
        Sid    = "AllowCloudTrailEncrypt"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = [
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        # Allow log decryption by authorized users
        Sid    = "AllowLogDecryption"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.current_account_id}:root"
        }
        Action = [
          "kms:Decrypt",
          "kms:ReEncryptFrom"
        ]
        Resource = "*"
        Condition = {
          StringEquals = {
            "kms:CallerAccount" = var.current_account_id
          }
        }
      }
    ]
  })

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-cloudtrail-encryption-key"
    Type    = "encryption"
    Purpose = "cloudtrail-encryption"
  })
}

resource "aws_kms_alias" "cloudtrail" {
  name          = "alias/${var.project_name}-cloudtrail-${var.environment}"
  target_key_id = aws_kms_key.cloudtrail.key_id
}

################################################
# KMS key in the DynamoDB replica region (us-west-2)
################################################
resource "aws_kms_key" "dynamodb_replica" {
  provider                = aws.us_west
  description             = "KMS key for DynamoDB replica table"
  deletion_window_in_days = 7 # adjust based on compliance needs
  enable_key_rotation     = true

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "EnableRootAccountPermissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.current_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "dynamodb_replica" {
  provider      = aws.us_west
  name          = "alias/${var.project_name}-dynamodb-replica-${var.environment}"
  target_key_id = aws_kms_key.dynamodb_replica.key_id
}

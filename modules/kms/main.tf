################################################
# KMS key for state encryption
################################################
# Secondary provider
provider "aws" {
  alias  = "us_west"
  region = var.secondary_region
}

resource "aws_kms_key" "terraform_state" {
  description             = "KMS key for Terraform state encryption"
  deletion_window_in_days = 7 # adjust based on compliance needs
  enable_key_rotation     = true
  rotation_period_in_days = 90

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
          AWS = var.iam_role_terraform_execution_arn
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
  name          = "alias/${var.naming_prefix}-terraform-state-key"
  target_key_id = aws_kms_key.terraform_state.key_id
}

#####################################################
# KMS replication key for Terraform state encryption
#####################################################
resource "aws_kms_key" "replication_state_key" {
  provider                = aws.us_west
  description             = "KMS key for S3 replication destination"
  deletion_window_in_days = 7 # adjust based on compliance needs
  enable_key_rotation     = true
  rotation_period_in_days = 90

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
    Type    = "encryption"
    Purpose = "encryption-replication-state-file"
  })
}

# Add KMS permissions to the replication role
resource "aws_iam_role_policy" "replication_kms" {
  name = "${var.naming_prefix}-s3-replication-kms-policy"
  role = var.iam_role_replication_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = aws_kms_key.terraform_state.arn
        Condition = {
          StringLike = {
            "kms:ViaService" = "s3.${var.primary_region}.amazonaws.com"
          }
        }
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt"
        ]
        Resource = aws_kms_key.replication_state_key.arn
        Condition = {
          StringLike = {
            "kms:ViaService" = "s3.${var.secondary_region}.amazonaws.com"
          }
        }
      }
    ]
  })
}

resource "aws_kms_alias" "replication_state_key" {
  provider      = aws.us_west
  name          = "alias/${var.naming_prefix}-replication-state-key"
  target_key_id = aws_kms_key.replication_state_key.key_id
}

#####################################################################
# KMS key for encrypting CloudTrail logs
# Encrypting CloudTrail logs with a customer-managed KMS key gives
# you control over who can read the logs
#####################################################################
resource "aws_kms_key" "cloudtrail" {
  description             = "KMS key for CloudTrail log encryption"
  deletion_window_in_days = 7 # adjust based on compliance needs
  enable_key_rotation     = true
  rotation_period_in_days = 90

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
  name          = "alias/${var.naming_prefix}-cloudtrail-encryption-key"
  target_key_id = aws_kms_key.cloudtrail.key_id
}

#####################################################
# KMS key in the DynamoDB replica region (us-west-2)
#####################################################
resource "aws_kms_key" "dynamodb_replica" {
  provider                = aws.us_west
  description             = "KMS key for DynamoDB replica table"
  deletion_window_in_days = 7 # adjust based on compliance needs
  enable_key_rotation     = true
  rotation_period_in_days = 90

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

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-dynamodb-replica-encryption-key"
    Type    = "encryption"
    Purpose = "dynamodb-table-encryption"
  })
}

resource "aws_kms_alias" "dynamodb_replica" {
  provider      = aws.us_west
  name          = "alias/${var.naming_prefix}-dynamodb-replica-encryption-key"
  target_key_id = aws_kms_key.dynamodb_replica.key_id
}

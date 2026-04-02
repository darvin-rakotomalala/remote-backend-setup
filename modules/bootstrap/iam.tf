#######################################################
# IAM role for Terraform execution (used in CI/CD)
#######################################################
resource "aws_iam_role" "terraform_execution" {
  name = "${var.project_name}-terraform-execution-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.current_account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            # Restrict OIDC trust to specific branches if needed.
            # Allow any branch in the repository
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/*"
            # "token.actions.githubusercontent.com:sub": "repo:your-username/aws-github-oidc:*"
          }
        }
      }
    ]
  })

  # Maximum session duration (1 hour for Terraform runs)
  max_session_duration = 3600

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-github-actions-oidc"
    Type    = "oidc-Authentication"
    Purpose = "oidc-provider-deployments"
  })
}

resource "aws_iam_role_policy_attachment" "terraform_execution_admin" {
  role = aws_iam_role.terraform_execution.name
  # Bad: Overly permissions
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # Scope down in production. Specific permissions for specific resources
}

# Read-only access (for developers reviewing infrastructure)
# Full access (for CI/CD and infrastructure team)
# Environment-specific access (production state)

/*
# Full access (for CI/CD and infrastructure team)
resource "aws_iam_policy" "terraform_state_full" {
  name        = "TerraformStateFullAccess"
  description = "Full access to Terraform state"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ManageStateBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning",
          "s3:PutBucketVersioning"
        ]
        Resource = "${aws_s3_bucket.terraform_state.arn}"
      },
      {
        Sid    = "ManageStateFiles"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      },
      {
        Sid    = "ManageLocks"
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:DeleteItem"
          "dynamodb:DescribeTable",
          "dynamodb:DeleteItem"
        ]
        Resource = "arn:aws:dynamodb:${var.current_region}:${var.current_account_id}:table/${aws_dynamodb_table.terraform_locks.name}"
      },
      {
        Sid    = "EncryptDecryptState"
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:DescribeKey",
          "kms:GenerateDataKey"
        ]
        Resource = "arn:aws:kms:${var.current_region}:${var.current_account_id}:key/*"
        Condition = {
          StringEquals = {
            "kms:ViaService" = "s3.${var.current_region}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "TerraformStateFullAccess"
  }
}
*/

# Bucket Policy for Defense in Depth
# Enforce encryption in transit
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      },
      {
        Sid       = "DenyUnencryptedObjectUploads"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.terraform_state.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Sid       = "EnforceMFAForDelete"
        Effect    = "Deny"
        Principal = "*"
        Action = [
          "s3:DeleteObject",
          "s3:DeleteObjectVersion"
        ]
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      },
      {
        Sid    = "AllowTerraformRoleAccess"
        Effect = "Allow"
        Principal = {
          Federated = "arn:aws:iam::${var.current_account_id}:oidc-provider/token.actions.githubusercontent.com"
        }
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.terraform_state.arn,
          "${aws_s3_bucket.terraform_state.arn}/*"
        ]
      }
    ]
  })
}

#######################################################
# IAM Role for CloudTrail
#######################################################
resource "aws_iam_role" "cloudtrail_logs" {
  name = "${var.project_name}-cloudtrail-logs-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      }
    }]
  })

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-cloudtrail-logs-role"
    Type    = "cloudtrail-logs"
    Purpose = "cloudtrail-logs-role"
  })
}

resource "aws_iam_role_policy" "cloudtrail_logs_policy" {
  name = "${var.project_name}-cloudtrail-logs-policy-${var.environment}"
  role = aws_iam_role.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Effect   = "Allow"
      Resource = "${aws_cloudwatch_log_group.terraform_state_log_group.arn}:*"
    }]
  })
}

#######################################################
# Set Up the Bucket Policy
# CloudTrail requires a specific bucket policy structure
#######################################################
resource "aws_s3_bucket_policy" "cloudtrail_audit_logs" {
  bucket = aws_s3_bucket.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AWSCloudTrailAclCheck"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:GetBucketAcl"
        Resource = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.bucket}"
        Condition = {
          StringEquals = {
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.current_region}:${var.current_account_id}:trail/${var.project_name}-terraform-state-audit-${var.environment}"
          }
        }
      },
      {
        Sid    = "AWSCloudTrailWrite"
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action   = "s3:PutObject"
        Resource = "arn:aws:s3:::${aws_s3_bucket.cloudtrail_logs.bucket}/AWSLogs/${var.current_account_id}/*"
        Condition = {
          StringEquals = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
            "aws:SourceArn" = "arn:aws:cloudtrail:${var.current_region}:${var.current_account_id}:trail/${var.project_name}-terraform-state-audit-${var.environment}"
          }
        }
      }
    ]
  })
}

#######################################################
# IAM Role for Replication
#######################################################
resource "aws_iam_role" "replication" {
  name = "${var.project_name}-s3-replication-role-${var.environment}"

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
    Type    = "notification"
    Purpose = "notification-replication-role"
  })
}

resource "aws_iam_role_policy" "replication" {
  name = "${var.project_name}-s3-replication-policy-${var.environment}"
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
        Resource = aws_s3_bucket.terraform_state.arn
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
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = "${aws_s3_bucket.state_backup_replica.arn}/*"
      }
    ]
  })
}

#######################################################
# IAM role for Terraform execution (used in CI/CD)
#######################################################

resource "aws_iam_openid_connect_provider" "github_actions" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
}

resource "aws_iam_role" "terraform_execution" {
  name = "${var.naming_prefix}-github-actions-role"

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
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_org}/${var.github_repo}:*"
          }
        }
      }
    ]
  })

  # Maximum session duration (1 hour for Terraform runs)
  max_session_duration = 3600

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-github-actions-oidc"
    Type    = "github-actions-role"
    Purpose = "oidc-provider-deployments"
  })
}

resource "aws_iam_role_policy_attachment" "terraform_execution_admin" {
  role = aws_iam_role.terraform_execution.name
  # Bad: Overly permissions
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess" # Scope down in production. Specific permissions for specific resources
}

/*
# Full access (for CI/CD and infrastructure team)
resource "aws_iam_policy" "terraform_state_full" {
  name        = "${var.naming_prefix}-TerraformStateFullAccess"
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

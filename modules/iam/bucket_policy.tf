####################################################
# Bucket Policy for Defense in Depth
# Enforce encryption in transit
####################################################
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = var.bucket_terraform_state_id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          var.bucket_terraform_state_arn,
          "${var.bucket_terraform_state_arn}/*"
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
        Resource  = "${var.bucket_terraform_state_arn}/*"
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
        Resource = "${var.bucket_terraform_state_arn}/*"
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
          var.bucket_terraform_state_arn,
          "${var.bucket_terraform_state_arn}/*"
        ]
      }
    ]
  })
}

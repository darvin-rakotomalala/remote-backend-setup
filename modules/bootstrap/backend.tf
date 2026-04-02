###############################################
# Backend configuration
###############################################
/*
terraform {
  backend "s3" {
    bucket = aws_s3_bucket.terraform_state.id
    key    = "${var.environment}/infrastructure/terraform.tfstate"
    region = var.primary_region
    # Encryption
    encrypt    = true # Encrypt state at rest
    kms_key_id = aws_kms_key.terraform_state.arn
    # State locking
    dynamodb_table = aws_dynamodb_table.terraform_locks.name
    # Lock acquisition timeout
    # Default: 0 (wait indefinitely)
    # Recommended: 5-10 minutes
    max_retries = 10
  }
}
*/

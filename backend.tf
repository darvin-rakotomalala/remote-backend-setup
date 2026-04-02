###############################################
# Backend configuration
###############################################
/*
terraform {
  backend "s3" {
    bucket = "ce-terraform-state-dev-current_account_id"
    key    = "dev/infrastructure/terraform.tfstate"
    region = "us-east-1"
    # Encryption
    encrypt    = true # Encrypt state at rest
    kms_key_id = "f0d07a59-3482-45cf-afab-0c656b89e24b"
    # State locking
    dynamodb_table = "ce-terraform-locks-dev"
    # Lock acquisition timeout
    # Default: 0 (wait indefinitely)
    # Recommended: 5-10 minutes
    max_retries = 10
  }
}
*/
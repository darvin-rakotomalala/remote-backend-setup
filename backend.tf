###############################################
# Backend configuration
###############################################

terraform {
  backend "s3" {
    bucket = "ce-dev-terraform-state-5bhkr8k3"
    key    = "dev/infrastructure/terraform.tfstate"
    region = "us-east-1"
    # Encryption
    encrypt    = true # Encrypt state at rest
    kms_key_id = "cd25fbac-3164-4aad-91a7-7cb1e95e3507"
    # State locking
    # dynamodb_table = "ce-dev-terraform-locks"
    use_lockfile = true
    # Lock acquisition timeout
    # Default: 0 (wait indefinitely)
    # Recommended: 5-10 minutes
    max_retries = 10
  }
}

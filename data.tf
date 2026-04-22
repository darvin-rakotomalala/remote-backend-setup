# Data sources
data "aws_caller_identity" "current" {}

# Get information about the current AWS region
data "aws_region" "current" {}

# AWS provider
terraform {
  required_version = ">= 1.14.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0" # Allows 6.x.x, blocks 7.0.0
    }
  }
}

# Primary provider
provider "aws" {
  region = var.primary_region
}

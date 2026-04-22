output "terraform_execution_role_arn" {
  description = "Terraform execution role ARN for GitHub Actions"
  value       = module.iam.iam_role_terraform_execution_arn
  sensitive   = false
}

output "backend_config" {
  description = "Backend configuration to use in other projects"
  value       = <<-EOT
  terraform {
    backend "s3" {
      bucket         = "${module.s3.bucket_terraform_state_id}"
      key            = "${var.environment}/infrastructure/terraform.tfstate"
      region         = "${var.primary_region}"
      encrypt        = true
      kms_key_id     = "${module.kms.terraform_state_kms_key_id}"
      dynamodb_table = "${module.dynamodb.dynamodb_table_name}"
    }
  }
  EOT
}

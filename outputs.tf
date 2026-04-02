output "state_bucket_name" {
  value = module.bootstrap.state_bucket_name
}

output "s3_bucket_arn" {
  value = module.bootstrap.s3_bucket_arn
}

output "dynamodb_table_name" {
  value = module.bootstrap.dynamodb_table_name
}

output "kms_key_id" {
  value = module.bootstrap.kms_key_id
}

output "kms_key_arn" {
  value = module.bootstrap.kms_key_arn
}

output "terraform_execution_role_arn" {
  value = module.bootstrap.terraform_execution_role_arn
}

output "terraform_execution_role_name" {
  value = module.bootstrap.terraform_execution_role_name
}

output "backend_config" {
  value = module.bootstrap.backend_config
}

output "destination_bucket" {
  value = module.bootstrap.destination_bucket
}
/*
# If you want to encode all outputs into a file, build the object explicitly:
resource "local_file" "output_file" {
  content = jsonencode({
    vpc_id     = module.bootstrap.vpc_id
    subnet_ids = module.bootstrap.subnet_ids
    # ... add your actual outputs here
  })
  filename = "${path.module}/outputs.json"
}

# If you're trying to reference a specific output value:
resource "local_file" "output_file" {
  content  = jsonencode(module.bootstrap.some_output)
  filename = "${path.module}/outputs.json"
}
*/

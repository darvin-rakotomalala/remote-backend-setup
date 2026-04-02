#########################################################
# Backend for Terraform Sate Management
#########################################################

module "bootstrap" {
  source              = "./modules/bootstrap"
  current_region      = data.aws_region.current.region
  current_account_id  = data.aws_caller_identity.current.account_id
  github_org          = var.github_org
  email_subscriptions = var.email_subscriptions
  environment         = var.environment
  primary_region      = var.primary_region
  project_name        = var.project_name
  secondary_region    = var.secondary_region
  naming_prefix       = local.naming_prefix
  common_tags         = local.common_tags
}

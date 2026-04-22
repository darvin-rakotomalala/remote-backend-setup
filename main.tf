#########################################################
# IAM
#########################################################

module "iam" {
  source                            = "./modules/iam"
  current_region                    = data.aws_region.current.region
  current_account_id                = data.aws_caller_identity.current.account_id
  github_org                        = var.github_org
  github_repo                       = var.github_repo
  naming_prefix                     = local.naming_prefix
  common_tags                       = local.common_tags
  bucket_state_backup_replica_arn   = module.s3.bucket_state_backup_replica_arn
  bucket_terraform_state_arn        = module.s3.bucket_terraform_state_arn
  bucket_terraform_state_id         = module.s3.bucket_terraform_state_id
  terraform_state_log_group_arn     = module.cloudwatch.terraform_state_log_group_arn
  primary_region                    = var.primary_region
  replication_state_key_kms_key_arn = module.kms.replication_state_key_kms_key_arn
  secondary_region                  = var.secondary_region
  terraform_state_kms_key_arn       = module.kms.terraform_state_kms_key_arn
}

#########################################################
# KMS
#########################################################

module "kms" {
  source                           = "./modules/kms"
  current_account_id               = data.aws_caller_identity.current.account_id
  naming_prefix                    = local.naming_prefix
  common_tags                      = local.common_tags
  iam_role_terraform_execution_arn = module.iam.iam_role_terraform_execution_arn
  secondary_region                 = var.secondary_region
  iam_role_replication_id          = module.iam.iam_role_replication_id
  primary_region                   = var.primary_region
}

#########################################################
# DYNAMODB
#########################################################

module "dynamodb" {
  source                       = "./modules/dynamodb"
  current_account_id           = data.aws_caller_identity.current.account_id
  naming_prefix                = local.naming_prefix
  common_tags                  = local.common_tags
  dynamodb_replica_kms_key_arn = module.kms.dynamodb_replica_kms_key_arn
  secondary_region             = var.secondary_region
  terraform_state_kms_key_arn  = module.kms.terraform_state_kms_key_arn
}

#########################################################
# S3
#########################################################

module "s3" {
  source                              = "./modules/s3"
  current_account_id                  = data.aws_caller_identity.current.account_id
  naming_prefix                       = local.naming_prefix
  common_tags                         = local.common_tags
  secondary_region                    = var.secondary_region
  terraform_state_kms_key_arn         = module.kms.terraform_state_kms_key_arn
  environment                         = var.environment
  iam_role_replication_arn            = module.iam.iam_role_replication_arn
  replication_state_key_kms_key_arn   = module.kms.replication_state_key_kms_key_arn
  sns_s3_event_notification_topic_arn = module.sns.sns_s3_event_notification_topic_arn
}

#########################################################
# SNS
#########################################################

module "sns" {
  source                     = "./modules/sns"
  current_account_id         = data.aws_caller_identity.current.account_id
  naming_prefix              = local.naming_prefix
  common_tags                = local.common_tags
  bucket_terraform_state_arn = module.s3.bucket_terraform_state_arn
  current_region             = data.aws_region.current.region
  email_subscriptions        = var.email_subscriptions
}

#########################################################
# CLOUDTRAIL
#########################################################

module "cloudtrail" {
  source                        = "./modules/cloudtrail"
  current_account_id            = data.aws_caller_identity.current.account_id
  naming_prefix                 = local.naming_prefix
  common_tags                   = local.common_tags
  environment                   = var.environment
  project_name                  = var.project_name
  bucket_terraform_state_arn    = module.s3.bucket_terraform_state_arn
  current_region                = data.aws_region.current.region
  cloudtrail_kms_key_arn        = module.kms.cloudtrail_kms_key_arn
  dynamodb_table_name           = module.dynamodb.dynamodb_table_name
  iam_role_cloudtrail_logs_arn  = module.iam.iam_role_cloudtrail_logs_arn
  terraform_state_log_group_arn = module.cloudwatch.terraform_state_log_group_arn
}

#########################################################
# CLOUDWATCH
#########################################################

module "cloudwatch" {
  source                            = "./modules/cloudwatch"
  naming_prefix                     = local.naming_prefix
  common_tags                       = local.common_tags
  bucket_state_backup_replica_id    = module.s3.bucket_state_backup_replica_id
  bucket_terraform_state_id         = module.s3.bucket_terraform_state_id
  dynamodb_table_name               = module.dynamodb.dynamodb_table_name
  dynamodb_table_terraform_locks_id = module.dynamodb.dynamodb_table_terraform_locks_id
  secondary_region                  = var.secondary_region
  sns_terraform_state_alerts_arn    = module.sns.sns_terraform_state_alerts_arn
}

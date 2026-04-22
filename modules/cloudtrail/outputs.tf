output "bucket_cloudtrail_logs_id" {
  description = "S3 bucket for cloudtrail logs ID"
  value       = aws_s3_bucket.cloudtrail_logs.id
}

output "bucket_cloudtrail_logs_bucket" {
  description = "S3 bucket for cloudtrail logs bucket"
  value       = aws_s3_bucket.cloudtrail_logs.bucket
}

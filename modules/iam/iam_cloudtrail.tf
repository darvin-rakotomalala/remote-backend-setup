#######################################################
# IAM Role for CloudTrail
#######################################################

resource "aws_iam_role" "cloudtrail_logs" {
  name = "${var.naming_prefix}-cloudtrail-logs-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "cloudtrail.amazonaws.com"
      }
    }]
  })

  tags = merge(var.common_tags, {
    Name    = "${var.naming_prefix}-cloudtrail-logs-role"
    Type    = "logs"
    Purpose = "cloudtrail-logs-role"
  })
}

resource "aws_iam_role_policy" "cloudtrail_logs_policy" {
  name = "${var.naming_prefix}-cloudtrail-logs-policy"
  role = aws_iam_role.cloudtrail_logs.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ]
      Effect   = "Allow"
      Resource = "${var.terraform_state_log_group_arn}:*"
    }]
  })
}

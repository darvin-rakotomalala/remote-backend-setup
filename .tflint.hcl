# .tflint.hcl
config {
  # Enable module inspection
  call_module_type = "all"
  # Treat warnings as errors in CI
  force = false
}

# AWS provider plugin
plugin "aws" {
  enabled = true
  version = "0.35.0"
  source  = "github.com/terraform-linters/tflint-ruleset-aws"
}

# Terraform language rules
plugin "terraform" {
  enabled = true
  preset  = "recommended"
}

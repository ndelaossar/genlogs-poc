provider "aws" {
  profile                     = var.aws_profile
  region                      = var.aws_region
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    # endpoint     = "http://localhost:4566"
    # sts_endpoint = "http://localhost:4566"
    # iam_endpoint = "http://localhost:4566"
    s3    = "http://localhost:4566"
    ec2   = "http://localhost:4566"
    elbv2 = "http://localhost:4566"
  }
}   
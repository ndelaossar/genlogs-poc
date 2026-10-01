terraform {
  backend "s3" {
    bucket  = "bucket-local"
    key     = "poc/terraform.tfstate"
    region  = "us-east-1"
    profile = "ministack" # mandatory for MiniStack

    # mandatory for MiniStack
    skip_credentials_validation = true
    skip_metadata_api_check     = true
    skip_region_validation      = true
    use_path_style              = true
  }
}
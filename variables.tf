variable "aws_region" {
  default = "us-east-1"
}
variable "aws_profile" {
  default = "ministack"
}
variable "user_data" {
  default = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              EOF
}

variable "app_name" {
  default = "poc"
}
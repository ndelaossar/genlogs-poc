# VPC
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "6.7.3"

  name = "${var.app_name}-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Terraform   = "true"
    Environment = "production"
    name        = "poc-vpc"
  }
}

locals {
  no_instances = length(module.vpc.private_subnets)
}


# Application Load Balancer configuration
resource "aws_lb" "poc_alb" {
  name               = "${var.app_name}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [for subnet in module.vpc.private_subnets : subnet]
}
# All http/https traffic will be allowed to the ALB from the internet, and the ALB will forward the traffic to the instances in the private subnets. The instances will only allow traffic from the ALB.
resource "aws_security_group" "alb_sg" {
  name        = "${var.app_name}-alb-sg"
  description = "Allow HTTP traffic to ALB"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group configuration
resource "aws_lb_target_group" "http_tg" {
  name        = "${var.app_name}-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = module.vpc.vpc_id
  target_type = "ip"
  # Health check configuration
  health_check {
    enabled             = true
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    healthy_threshold   = 2
    unhealthy_threshold = 3
    timeout             = 5
    interval            = 30
    matcher             = "200"
  }
  # Deregistration delay - how long to wait before removing targets
  deregistration_delay = 30

  lifecycle {
    create_before_destroy = true
  }

}

resource "aws_lb_target_group_attachment" "http_tg_attachment" {
  count            = local.no_instances
  target_group_arn = aws_lb_target_group.http_tg.arn
  target_id        = aws_instance.poc_instance[count.index].private_ip
  port             = 80
}

# Listener configuration
# Redirect HTTP to HTTPS
resource "aws_lb_listener" "redirect_http_to_https" {
  load_balancer_arn = aws_lb.poc_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

# HTTPS listener configuration
resource "aws_lb_listener" "https_listener" {
  load_balancer_arn = aws_lb.poc_alb.arn
  port              = "443"
  protocol          = "HTTPS"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.http_tg.arn
  }
}

# Security Group for EC2 instances
resource "aws_security_group" "poc_instance_sg" {
  name        = "${var.app_name}-instance-sg"
  description = "Allow traffic from ALB to instances"
  vpc_id      = module.vpc.vpc_id
  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 Instances configuration
resource "aws_instance" "poc_instance" {
  count                       = local.no_instances
  ami                         = "ami-024f768332f0" # Amazon Linux 2 AMI
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.private_subnets[count.index]
  associate_public_ip_address = false
  security_groups             = [aws_security_group.poc_instance_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              sudo yum update -y
              sudo yum install -y nginx
              sudo systemctl start nginx
              sudo systemctl enable nginx
              EOF
  tags = {
    Name = "poc-web-instance-${count.index}"
  }
  depends_on = [module.vpc, aws_security_group.poc_instance_sg]
}



# Output the ALB DNS name
output "alb_dns_name" {
  value = aws_lb.poc_alb.dns_name
}
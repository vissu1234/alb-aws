module "alb" {
  source = "./module"

  region     = "us-east-1"
  prefix     = "myapp"
  vpc_id     = "vpc-12345678"
  subnet_ids = ["subnet-12345678", "subnet-23456789"]
  
  # ALB Configuration
  internal                  = false
  enable_deletion_protection = false
  logs_bucket               = "my-alb-logs-bucket"
  
  # Certificate Configuration
  create_certificate        = true
  domain_name               = "myapp.example.com"
  subject_alternative_names = ["*.myapp.example.com"]
  route53_zone_id           = "Z1234567890ABCDEFGHIJ"
  
  # Define target groups
  target_groups = {
    api = {
      port              = 8080
      protocol          = "HTTP"
      target_type       = "instance"
      health_check_path = "/health"
    },
    web = {
      port              = 80
      protocol          = "HTTP"
      target_type       = "instance"
      health_check_path = "/index.html"
    }
  }
  
  # Default target group for HTTPS listener
  default_target_group = "web"
  
  # Attach instances to target groups
  target_group_attachments = [
    {
      target_group = "api"
      target_id    = "i-12345678901234567"
      port         = 8080
    },
    {
      target_group = "web"
      target_id    = "i-abcdef1234567890"
      port         = 80
    }
  ]
  
  # Define listener rules
  listener_rules = {
    api = {
      priority      = 100
      action_type   = "forward"
      target_group  = "api"
      path_pattern  = ["/api/*"]
    },
    admin = {
      priority      = 200
      action_type   = "forward"
      target_group  = "api"
      host_header   = ["admin.myapp.example.com"]
    }
  }
  
  # WAF integration
  waf_web_acl_arn = "arn:aws:wafv2:us-east-1:123456789012:global/webacl/my-web-acl/abcdef-1234-5678-90ab-cdef"
  
  # Common tags
  common_tags = {
    Environment = "production"
    Project     = "MyApp"
    Terraform   = "true"
  }
}
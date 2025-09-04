variable "region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "prefix" {
  description = "Prefix for resource naming"
  type        = string
  default     = "app"
}

variable "vpc_id" {
  description = "VPC ID where the ALB will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "Subnet IDs where the ALB will be deployed"
  type        = list(string)
}

variable "internal" {
  description = "Whether the ALB is internal"
  type        = bool
  default     = false
}

variable "idle_timeout" {
  description = "The time in seconds that the connection is allowed to be idle"
  type        = number
  default     = 60
}

variable "enable_deletion_protection" {
  description = "Enable deletion protection on the ALB"
  type        = bool
  default     = false
}

variable "logs_bucket" {
  description = "S3 bucket for ALB access logs"
  type        = string
}

variable "common_tags" {
  description = "Common tags to be applied to all resources"
  type        = map(string)
  default     = {}
}

variable "alb_ingress_rules" {
  description = "List of ingress rules for the ALB security group"
  type = list(object({
    port        = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
  default = [
    {
      port        = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTP"
    },
    {
      port        = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
      description = "HTTPS"
    }
  ]
}
variable "alb_ingress_rules" {
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = optional(string)
  }))
}
variable "target_groups" {
  description = "Map of target groups to create"
  type = map(object({
    port                   = number
    protocol               = string
    target_type            = string
    health_check_path      = string
    health_check_port      = optional(string)
    health_check_protocol  = optional(string)
    health_check_timeout   = optional(number)
    health_check_interval  = optional(number)
    health_check_matcher   = optional(string)
    healthy_threshold      = optional(number)
    unhealthy_threshold    = optional(number)
    deregistration_delay   = optional(number)
    stickiness_enabled     = optional(bool)
    stickiness_duration    = optional(number)
  }))
}

variable "target_group_attachments" {
  description = "List of target group attachments"
  type = list(object({
    target_group = string
    target_id    = string
    port         = optional(number)
  }))
  default = []
}

variable "default_target_group" {
  description = "Name of the default target group for HTTPS listener"
  type        = string
}

variable "ssl_policy" {
  description = "SSL Policy for the HTTPS listener"
  type        = string
  default     = "ELBSecurityPolicy-TLS13-1-2-2021-06"
}

variable "create_certificate" {
  description = "Whether to create a new certificate"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of the certificate to use for the HTTPS listener (if create_certificate is false)"
  type        = string
  default     = ""
}

variable "domain_name" {
  description = "Domain name for the ALB"
  type        = string
}

variable "subject_alternative_names" {
  description = "Subject alternative names for the certificate"
  type        = list(string)
  default     = []
}

variable "route53_zone_id" {
  description = "Route53 zone ID where the DNS record will be created"
  type        = string
}

variable "listener_rules" {
  description = "Map of listener rules for the HTTPS listener"
  type = map(object({
    priority      = number
    action_type   = string
    target_group  = optional(string)
    host_header   = optional(list(string))
    path_pattern  = optional(list(string))
    http_header   = optional(object({
      name   = string
      values = list(string)
    }))
    redirect_config = optional(object({
      path        = optional(string)
      port        = optional(string)
      protocol    = optional(string)
      status_code = optional(string)
    }))
  }))
  default = {}
}

variable "waf_web_acl_arn" {
  description = "ARN of the WAF Web ACL to associate with the ALB"
  type        = string
  default     = ""
}

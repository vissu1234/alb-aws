provider "aws" {
  region = var.region
}

# ALB Security Group
resource "aws_security_group" "alb_sg" {
  name        = "${var.prefix}-alb-sg"
  description = "Security group for ALB"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.alb_ingress_rules
    content {
      from_port   = ingress.value.port
      to_port     = ingress.value.port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
      description = ingress.value.description
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-alb-sg"
    }
  )
}

# Application Load Balancer
resource "aws_lb" "this" {
  name               = "${var.prefix}-alb"
  internal           = var.internal
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = var.enable_deletion_protection
  drop_invalid_header_fields = true
  idle_timeout               = var.idle_timeout

  access_logs {
    bucket  = var.logs_bucket
    prefix  = "alb-logs"
    enabled = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-alb"
    }
  )
}

# Target Groups
resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name                 = "${var.prefix}-${each.key}-tg"
  port                 = each.value.port
  protocol             = each.value.protocol
  vpc_id               = var.vpc_id
  target_type          = each.value.target_type
  deregistration_delay = lookup(each.value, "deregistration_delay", 300)

  health_check {
    enabled             = true
    path                = each.value.health_check_path
    port                = lookup(each.value, "health_check_port", "traffic-port")
    protocol            = lookup(each.value, "health_check_protocol", each.value.protocol)
    healthy_threshold   = lookup(each.value, "healthy_threshold", 3)
    unhealthy_threshold = lookup(each.value, "unhealthy_threshold", 3)
    timeout             = lookup(each.value, "health_check_timeout", 5)
    interval            = lookup(each.value, "health_check_interval", 30)
    matcher             = lookup(each.value, "health_check_matcher", "200-299")
  }

  stickiness {
    type            = "lb_cookie"
    cookie_duration = lookup(each.value, "stickiness_duration", 86400)
    enabled         = lookup(each.value, "stickiness_enabled", false)
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-${each.key}-tg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Target Group Attachments
resource "aws_lb_target_group_attachment" "this" {
  for_each = {
    for idx, attachment in var.target_group_attachments : "${attachment.target_group}-${idx}" => attachment
  }

  target_group_arn = aws_lb_target_group.this[each.value.target_group].arn
  target_id        = each.value.target_id
  port             = lookup(each.value, "port", null)
}

# ACM Certificate Validation
resource "aws_acm_certificate" "this" {
  count             = var.create_certificate ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"
  
  subject_alternative_names = var.subject_alternative_names

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-acm-cert"
    }
  )
}

resource "aws_route53_record" "cert_validation" {
  for_each = var.create_certificate ? {
    for dvo in aws_acm_certificate.this[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "this" {
  count                   = var.create_certificate ? 1 : 0
  certificate_arn         = aws_acm_certificate.this[0].arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# ALB Listeners
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
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

  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-http-listener"
    }
  )
}

resource "aws_lb_listener" "https" {
  load_balancer_arn = aws_lb.this.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = var.ssl_policy
  certificate_arn   = var.create_certificate ? aws_acm_certificate_validation.this[0].certificate_arn : var.certificate_arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[var.default_target_group].arn
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-https-listener"
    }
  )
}

# ALB Listener Rules
resource "aws_lb_listener_rule" "https_rules" {
  for_each     = var.listener_rules
  listener_arn = aws_lb_listener.https.arn
  priority     = each.value.priority

  action {
    type             = each.value.action_type
    target_group_arn = lookup(each.value, "target_group", null) != null ? aws_lb_target_group.this[each.value.target_group].arn : null

    dynamic "redirect" {
      for_each = each.value.action_type == "redirect" ? [1] : []
      content {
        path        = lookup(each.value.redirect_config, "path", "/${each.key}")
        port        = lookup(each.value.redirect_config, "port", "443")
        protocol    = lookup(each.value.redirect_config, "protocol", "HTTPS")
        status_code = lookup(each.value.redirect_config, "status_code", "HTTP_301")
      }
    }
  }

  dynamic "condition" {
    for_each = lookup(each.value, "host_header", null) != null ? [1] : []
    content {
      host_header {
        values = each.value.host_header
      }
    }
  }

  dynamic "condition" {
    for_each = lookup(each.value, "path_pattern", null) != null ? [1] : []
    content {
      path_pattern {
        values = each.value.path_pattern
      }
    }
  }

  dynamic "condition" {
    for_each = lookup(each.value, "http_header", null) != null ? [1] : []
    content {
      http_header {
        http_header_name = each.value.http_header.name
        values           = each.value.http_header.values
      }
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-rule-${each.key}"
    }
  )
}

# Route53 Record for ALB
resource "aws_route53_record" "alb" {
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"

  alias {
    name                   = aws_lb.this.dns_name
    zone_id                = aws_lb.this.zone_id
    evaluate_target_health = true
  }
}

# WAF Web ACL Association
resource "aws_wafv2_web_acl_association" "this" {
  count        = var.waf_web_acl_arn != "" ? 1 : 0
  resource_arn = aws_lb.this.arn
  web_acl_arn  = var.waf_web_acl_arn
}

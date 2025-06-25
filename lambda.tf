# main.tf

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

  tags = merge(var.common_tags, { Name = "${var.prefix}-alb-sg" })
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

  tags = merge(var.common_tags, { Name = "${var.prefix}-alb" })
}

# Target Groups
resource "aws_lb_target_group" "this" {
  for_each = var.target_groups

  name                 = "${var.prefix}-${each.key}-tg"
  target_type          = each.value.target_type
  port                 = each.value.target_type == "lambda" ? null : each.value.port
  protocol             = each.value.protocol
  vpc_id               = each.value.target_type == "lambda" ? null : var.vpc_id
  deregistration_delay = lookup(each.value, "deregistration_delay", 300)

  dynamic "health_check" {
    for_each = each.value.target_type == "lambda" ? [] : [1]
    content {
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
  }

  dynamic "stickiness" {
    for_each = each.value.target_type == "lambda" ? [] : [1]
    content {
      type            = "lb_cookie"
      cookie_duration = lookup(each.value, "stickiness_duration", 86400)
      enabled         = lookup(each.value, "stickiness_enabled", false)
    }
  }

  tags = merge(var.common_tags, { Name = "${var.prefix}-${each.key}-tg" })

  lifecycle {
    create_before_destroy = true
  }
}

# Lambda Target Registration
resource "aws_lb_target_group_attachment" "lambda" {
  for_each = {
    for k, v in var.target_groups :
    k => v if v.target_type == "lambda"
  }

  target_group_arn = aws_lb_target_group.this[each.key].arn
  target_id        = each.value.lambda_function_arn
}

# Lambda Permission for ALB
resource "aws_lambda_permission" "alb_invoke" {
  for_each = {
    for k, v in var.target_groups :
    k => v if v.target_type == "lambda"
  }

  statement_id  = "AllowExecutionFromALB-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.lambda_function_arn
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb_target_group.this[each.key].arn
}

# Listener Rule for Lambda
resource "aws_lb_listener_rule" "lambda_rule" {
  for_each = {
    for k, v in var.target_groups :
    k => v if v.target_type == "lambda"
  }

  listener_arn = var.listener_arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this[each.key].arn
  }

  condition {
    path_pattern {
      values = [each.value.path_pattern]
    }
  }
}

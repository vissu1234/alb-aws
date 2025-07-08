resource "aws_lb_listener_rule" "http_lambda_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this["lambda"].arn
  }

  condition {
    path_pattern {
      values = ["/lambda"]
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-http-lambda-rule"
    }
  )
}

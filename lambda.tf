# ------------------------------
# Lambda IAM Role
# ------------------------------
resource "aws_iam_role" "lambda_exec" {
  name = "${var.prefix}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "lambda.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ------------------------------
# Lambda Function
# ------------------------------
resource "aws_lambda_function" "backend" {
  function_name = "${var.prefix}-backend-lambda"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "index.handler"
  runtime       = "nodejs18.x"

  filename         = var.lambda_zip_path
  source_code_hash = filebase64sha256(var.lambda_zip_path)

  tags = var.common_tags
}

# ------------------------------
# ALB Permission to Invoke Lambda
# ------------------------------
resource "aws_lambda_permission" "allow_alb" {
  statement_id  = "AllowALBInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  principal     = "elasticloadbalancing.amazonaws.com"
  source_arn    = aws_lb.this.arn
}

# ------------------------------
# Lambda Target Group
# ------------------------------
resource "aws_lb_target_group" "lambda_tg" {
  name        = "${var.prefix}-lambda-tg"
  target_type = "lambda"
  vpc_id      = var.vpc_id  # Required by AWS even though Lambda doesn't use it
}

# ------------------------------
# Attach Lambda to Target Group
# ------------------------------
resource "aws_lb_target_group_attachment" "lambda_attach" {
  target_group_arn = aws_lb_target_group.lambda_tg.arn
  target_id        = aws_lambda_function.backend.arn
}

# ------------------------------
# Listener Rule to Forward to Lambda
# ------------------------------
resource "aws_lb_listener_rule" "lambda_rule" {
  listener_arn = aws_lb_listener.https.arn
  priority     = 10

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lambda_tg.arn
  }

  condition {
    path_pattern {
      values = ["/lambda"]
    }
  }

  tags = var.common_tags
}
variable "prefix" {
  description = "Prefix for resource names"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID (required by ALB even for Lambda target groups)"
  type        = string
}

variable "lambda_zip_path" {
  description = "Path to zipped Lambda source code"
  type        = string
}

variable "common_tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
}

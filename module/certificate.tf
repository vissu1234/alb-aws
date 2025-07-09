variable "acm_cert_groups" {
  description = "ACM certificate groups (e.g., dev, qa, prod) with domain configs"
  type = map(object({
    domain_name               = string
    subject_alternative_names = list(string)
  }))
}






resource "aws_acm_certificate" "group" {
  for_each = var.acm_cert_groups

  domain_name               = each.value.domain_name
  validation_method         = "DNS"
  subject_alternative_names = each.value.subject_alternative_names

  lifecycle {
    create_before_destroy = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-${each.key}-acm-cert"
    }
  )
}




resource "aws_route53_record" "cert_validation" {
  for_each = {
    for group_key, cert in aws_acm_certificate.group :
    for dvo in cert.domain_validation_options :
    "${group_key}__${dvo.domain_name}" => {
      group_key = group_key
      name      = dvo.resource_record_name
      record    = dvo.resource_record_value
      type      = dvo.resource_record_type
    }
  }

  zone_id = var.route53_zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 60
  records = [each.value.record]
}

resource "aws_acm_certificate_validation" "group" {
  for_each = aws_acm_certificate.group

  certificate_arn         = each.value.arn
  validation_record_fqdns = [
    for record in aws_route53_record.cert_validation :
    record.value.group_key == each.key ? record.value.name : null
  ]
}

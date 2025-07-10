variable "use_third_party_cert" {
  description = "Set to true if using a third-party certificate instead of ACM-managed"
  type        = bool
  default     = false
}

variable "certificate_arn" {
  description = "ARN of manually imported third-party ACM certificate (used if use_third_party_cert = true)"
  type        = string
  default     = ""
}

variable "third_party_cert_path" {
  description = "Path to the third-party certificate PEM file (optional, if uploading via Terraform)"
  type        = string
  default     = ""
}

variable "third_party_key_path" {
  description = "Path to the third-party private key PEM file"
  type        = string
  default     = ""
}

variable "third_party_chain_path" {
  description = "Path to the third-party certificate chain PEM file"
  type        = string
  default     = ""
}


resource "aws_acm_certificate" "third_party" {
  count             = var.use_third_party_cert && var.certificate_arn == "" ? 1 : 0
  private_key       = file(var.third_party_key_path)
  certificate_body  = file(var.third_party_cert_path)
  certificate_chain = file(var.third_party_chain_path)

  tags = merge(
    var.common_tags,
    {
      Name = "${var.prefix}-third-party-cert"
    }
  )
}


 3. Modify the aws_lb_listener.https Block:
Replace this line:

hcl
Copy
Edit
certificate_arn = var.create_certificate ? aws_acm_certificate_validation.this[0].certificate_arn : var.certificate_arn
With this logic:

hcl
Copy
Edit
certificate_arn = var.use_third_party_cert ?
  (var.certificate_arn != "" ? var.certificate_arn : aws_acm_certificate.third_party[0].arn)
  : aws_acm_certificate_validation.this[0].certificate_arn

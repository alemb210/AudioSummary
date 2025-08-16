resource "aws_route53_zone" "zone" {
  name = var.domain_name
}

//A DNS Record: IPV4 mapping for the CloudFront distribution
resource "aws_route53_record" "cf_alias_a" {
  for_each = toset(var.aliases)

  zone_id = aws_route53_zone.zone.zone_id
  name    = each.value
  type    = "A"

  alias {
    name                   = var.cloudfront_domain_name
  zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}

//AAAA DNS Record: IPV6 mapping for the CloudFront distribution
resource "aws_route53_record" "cf_alias_aaaa" {
  for_each = toset(var.aliases)

  zone_id = aws_route53_zone.zone.zone_id
  name    = each.value
  type    = "AAAA"

  alias {
    name                   = var.cloudfront_domain_name
  zone_id                = var.cloudfront_hosted_zone_id
    evaluate_target_health = false
  }
}


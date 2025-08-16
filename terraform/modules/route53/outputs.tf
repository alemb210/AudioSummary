output "zone_id" {
  description = "Hosted zone ID"
  value       = aws_route53_zone.zone.zone_id
}

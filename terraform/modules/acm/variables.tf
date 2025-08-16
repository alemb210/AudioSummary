variable "domain_name" {
  description = "The domain name for the ACM certificate."
  type        = string
}

variable "sans" {
  description = "Subject Alternative Names for the ACM certificate, ex www.example.com -> example.com"
  type        = list(string)
  default     = []
}

variable "zone_id" {
  description = "Route 53 hosted zone ID where validation records will be created."
  type        = string
}


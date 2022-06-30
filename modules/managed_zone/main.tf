
## Create the zone for the subdomain in Google Cloud DNS
resource "google_dns_managed_zone" "default" {
  name        = var.managed_zone_name
  dns_name    = var.hosted_zone_dns_name
  project     = var.project_id
  description = "Managed by Terraform"
}

output "managed_zone_name" {
  value = google_dns_managed_zone.default.name
}

output "managed_zone_dns_name" {
  value = google_dns_managed_zone.default.dns_name
}


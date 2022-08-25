resource "google_storage_bucket" "webbucket" {
  provider = google
  uniform_bucket_level_access = true
  project  = var.project_id
  // The name of the bucket is the dns name without the trailing dot
  name     = var.website_dns_name
  location = var.region
  website {
    main_page_suffix = var.index_page
    not_found_page   = var.not_found_page
  }
  force_destroy = true
}

# Set the default access control for readers to allow allUsers
resource "google_storage_bucket_iam_binding" "binding" {
  bucket = google_storage_bucket.webbucket.name
  role = "roles/storage.objectViewer"
  members = [
    "allUsers"
  ]
}

## External IP Address for load balancer
resource "google_compute_global_address" "static" {
  name        = "${var.configuration_name}-website-lb-ip"
  description = "Static external IP address for hosting"
}

## Add an A record for it
resource "google_dns_record_set" "a" {
  managed_zone = var.managed_zone_name
  name         = "${var.website_dns_name}."
  type         = "A"
  ttl          = 300

  rrdatas = [google_compute_global_address.static.address]
}

### Add a CNAME record for the www subdomain
#resource "google_dns_record_set" "cname" {
#  managed_zone = var.managed_zone_name
#  name         = "www.${var.website_dns_name}."
#  type         = "CNAME"
#  ttl          = 300
#
#  rrdatas = ["${var.website_dns_name}."]
#}

## HTTPS load balancer for backend bucket
resource "google_compute_backend_bucket" "webbucket_backend" {
  name        = "${var.configuration_name}-backend-webbucket"
  bucket_name = google_storage_bucket.webbucket.name
  enable_cdn  = false
}

## Partial HTTP load balancer redirects to HTTPS
resource "google_compute_url_map" "static_http" {
  name = "${var.configuration_name}-static-http-redirect"
  default_service = google_compute_backend_bucket.webbucket_backend.id
}

## Route incoming HTTP requests to a URL map
resource "google_compute_target_http_proxy" "static" {
  name    = "${var.configuration_name}-static-http-proxy"
  url_map = google_compute_url_map.static_http.id
}

## Create a Google managed SSL certificate resource
resource "google_compute_managed_ssl_certificate" "default" {
  name = "${var.configuration_name}-cert"

  managed {
    domains = [var.website_dns_name]
  }
}

## Route incoming HTTPS requests to a URL map
resource "google_compute_target_https_proxy" "default" {
  name             = "${var.configuration_name}-proxy"
  url_map          = google_compute_url_map.static_http.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}

resource "google_compute_global_forwarding_rule" "default" {
  name                  = "${var.configuration_name}-ssl-proxy-xlb-forwarding-rule"
  provider              = google
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  target                = google_compute_target_https_proxy.default.id
  ip_address            = google_compute_global_address.static.id
}

resource "google_compute_global_forwarding_rule" "static_http" {
  name       = "${var.configuration_name}-static-forwarding-rule-http"
  target     = google_compute_target_http_proxy.static.id
  port_range = "80"
  ip_address = google_compute_global_address.static.id
}

# SSL Policies
resource "google_compute_ssl_policy" "tls12_modern" {
  name            = "${var.configuration_name}-static-ssl-policy"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}

output "name" {
  value = google_storage_bucket.webbucket.name
}

# Put a temporary index file in the bucket for verification purposes
resource "google_storage_bucket_object" "index" {
  depends_on = [google_storage_bucket.webbucket]
  name       = var.index_page
  content    = "<h1>${google_storage_bucket.webbucket.name}</h1>"
  bucket     = google_storage_bucket.webbucket.name
}

# Put a temporary "not found" file in the bucket for verification purposes
resource "google_storage_bucket_object" "not_found_page" {
  depends_on = [google_storage_bucket.webbucket]
  name       = var.not_found_page
  content_type = "text/html"
  content_encoding = "UTF-8"
  source    = "404.html"
  bucket     = google_storage_bucket.webbucket.name
}

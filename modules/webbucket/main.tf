#locals

locals {
  create_index_page     = var.index_page.create ? 1 : 0
  create_not_found_page = var.not_found_page.create ? 1 : 0
}

# The bucket itsel1
resource "google_storage_bucket" "webbucket" {
  project                     = var.project_id
  provider                    = google
  uniform_bucket_level_access = true
  // The name of the bucket is the dns name without the trailing dot
  name     = var.website_dns_name
  location = var.region
  website {
    main_page_suffix = var.index_page.name
    not_found_page   = var.not_found_page.name
  }
  force_destroy = true
}

resource "google_compute_global_forwarding_rule" "https" {
  provider              = google-beta
  project               = var.project_id
  name                  = "${var.configuration_name}-ssl-proxy-xlb-forwarding-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443"
  target                = google_compute_target_https_proxy.default.self_link
  ip_address            = google_compute_global_address.static.self_link
}

resource "google_compute_global_forwarding_rule" "http" {
  provider   = google-beta
  project    = var.project_id
  name       = "${var.configuration_name}-static-forwarding-rule-http"
  target     = google_compute_target_http_proxy.default.self_link
  port_range = "80"
  ip_address = google_compute_global_address.static.self_link
}

# Set the default access control for readers to allow allUsers
resource "google_storage_bucket_iam_binding" "binding" {
  bucket = google_storage_bucket.webbucket.name
  role   = "roles/storage.objectViewer"
  members = [
    "allUsers"
  ]
}

## External IP Address for load balancer
resource "google_compute_global_address" "static" {
  project     = var.project_id
  name        = "${var.configuration_name}-website-lb-ip"
  description = "Static external IP address for hosting"
}

## Add an A record for it
resource "google_dns_record_set" "a" {
  project      = var.project_id
  managed_zone = var.managed_zone_name
  name         = "${var.website_dns_name}."
  type         = "A"
  ttl          = 300

  rrdatas = [google_compute_global_address.static.address]
}

## HTTPS load balancer for backend bucket
resource "google_compute_backend_bucket" "webbucket_backend" {
  project     = var.project_id
  name        = "${var.configuration_name}-backend-webbucket"
  bucket_name = google_storage_bucket.webbucket.name
  enable_cdn  = false
}

## Partial HTTP load balancer redirects to HTTPS
resource "google_compute_url_map" "static_http" {
  project         = var.project_id
  name            = "${var.configuration_name}-static-http-redirect"
  default_service = google_compute_backend_bucket.webbucket_backend.id
}

## URL map redirecting to https
resource "google_compute_url_map" "https_redirect" {
  project = var.project_id
  name    = "${var.configuration_name}-https-redirect"
  default_url_redirect {
    https_redirect         = true
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = false
  }
}

## Route incoming HTTP requests to a URL map
resource "google_compute_target_http_proxy" "default" {
  project = var.project_id
  name    = "${var.configuration_name}-static-http-proxy"
  url_map = google_compute_url_map.https_redirect.self_link
}

## Create a Google managed SSL certificate resource
resource "google_compute_managed_ssl_certificate" "default" {
  project = var.project_id
  name    = "${var.configuration_name}-cert"

  managed {
    domains = [var.website_dns_name]
  }
}

## Route incoming HTTPS requests to a URL map
resource "google_compute_target_https_proxy" "default" {
  project          = var.project_id
  name             = "${var.configuration_name}-proxy"
  url_map          = google_compute_url_map.static_http.id
  ssl_certificates = [google_compute_managed_ssl_certificate.default.id]
}

# SSL Policies
resource "google_compute_ssl_policy" "tls12_modern" {
  project         = var.project_id
  name            = "${var.configuration_name}-static-ssl-policy"
  profile         = "MODERN"
  min_tls_version = "TLS_1_2"
}

output "name" {
  value = google_storage_bucket.webbucket.name
}

# Put a temporary index file in the bucket for verification purposes
resource "google_storage_bucket_object" "index" {
  count      = local.create_index_page
  depends_on = [google_storage_bucket.webbucket]
  name       = var.index_page.name
  content    = "<h1>${google_storage_bucket.webbucket.name}</h1>"
  bucket     = google_storage_bucket.webbucket.name
}

# Put a temporary "not found" file in the bucket for verification purposes
resource "google_storage_bucket_object" "not_found_page" {
  count            = local.create_index_page
  depends_on       = [google_storage_bucket.webbucket]
  name             = var.not_found_page.name
  content_type     = "text/html"
  content_encoding = "UTF-8"
  source           = "404.html"
  bucket           = google_storage_bucket.webbucket.name
}

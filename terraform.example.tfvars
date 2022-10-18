project_id = "your-project"
region = "us-central1"
hosted_zone_dns_name = "yourcompany.com."
websites = {
  your-webbucket = {
    website_dns_name      = "www.yourcompany.com" # No trailing period
    index_page            = "index.html"
  }
  your-other-webbucket = {
    website_dns_name      = "support.yourcompany.com" # No trailing period
    index_page            = "home.html"
  }
}
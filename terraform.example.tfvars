project_id           = "your-project"
region               = "us-central1"
hosted_zone_dns_name = "yourcompany.com."
websites = {
  your-webbucket = {
    website_dns_name = "www.yourcompany.com" #
    index_page = {
      name : "index.html"
    create : false }
  }
  your-other-webbucket = {
    website_dns_name = "support.yourcompany.com" # No trailing period
    index_page = {
      name : "home.html"
    create : true }
  }
}

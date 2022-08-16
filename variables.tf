variable "project_id" {}
variable "region" {}
variable "hosted_zone_name" {
}
variable "hosted_zone_dns_name" {
  # Note that this has to be an absolute domain name (i.e. a trailing period. see RFC 1034)
  # Example "example.com."
}
variable "websites" {
  type = map(object({
    website_dns_name = string
    index_page       = string
  }))
}
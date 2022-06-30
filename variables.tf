variable "project_id" {}
variable "region" {}
variable "hosted_zone_name" {
  default = "radar-zone"
}
variable "hosted_zone_dns_name" {
  # Note that this has to be an absolute domain name (i.e. a trailing period. see RFC 1034)
  default = "example.com."
}
variable "websites" {
  type = map(object({
    website_dns_name = string
    index_page       = string
  }))
}
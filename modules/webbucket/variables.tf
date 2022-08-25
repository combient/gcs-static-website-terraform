variable "project_id" {
  description = "The id of the project. The project is assumed to exist"
}
variable "region" {
  description = "A google cloud region. See https://cloud.google.com/compute/docs/regions-zones"
}
variable "managed_zone_name" {
  description = "The name of the managed zone resource. Typically something like 'myprojectid-4711-zone'"
}
variable "configuration_name" {
  description = "A descriptive name for the configuration that complies with resource naming format rules for example 'my-website'"
}
variable "website_dns_name" {
  description = "The dns name of the website without the trailing period. Example: yoursite.com"
}
variable "index_page" {
  description = "The filename of the index page."
  default = "index.html"
}
variable "not_found_page" {
  description = "The filename 404 page."
  default = "404.html"
}
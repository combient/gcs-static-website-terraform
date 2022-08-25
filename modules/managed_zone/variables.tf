variable "managed_zone_name" {
  description = "The name of the managed zone resource. Typically something like 'myprojectid-4711-zone'"
}
variable "hosted_zone_dns_name" {
  description = "The FQDN (Fully Qualified Domain Name). Example 'yourdomain.com.'"
}
variable "project_id" {
  description = "The id of the project. Example: 'myprojectid-4711' The project is assumed to exist."
}
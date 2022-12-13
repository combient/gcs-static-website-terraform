variable "project_id" {
  description = "The id of the project. This is a string like 'my_project'"
}

variable "project_number" {
  description = "The numeric id of the project. This is an integer"
}

variable "service_account_user_name" {
  description = "The name before the @-sign of the service account"
}

variable "org_name" {
  description = "The name of the organization in GCP"
}

variable "website_dns_name" {
  description = "The dns name of the website without the trailing period. Example: yoursite.com"
}

variable "github_action_name" {
  description = "The name of the github action"
}
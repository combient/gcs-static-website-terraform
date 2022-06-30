terraform {
  required_version = ">= 0.14"
  backend "gcs" {}
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">=3.9.0"
    }
  }
}

provider "google" {
  region  = var.region
  project = var.project_id
}

provider "google-beta" {
  region  = var.region
  project = var.project_id
}

## Typically only need one of these
module "managed_zone" {
  source               = "./modules/managed_zone"
  project_id           = var.project_id
  region               = var.region
  managed_zone_name    = var.hosted_zone_name
  hosted_zone_dns_name = var.hosted_zone_dns_name
}

## Create a webbucket per configuration entry var.websites
module "webbucket" {
  source            = "./modules/webbucket"
  for_each = var.websites
  name              = each.key
  website_dns_name  = each.value["website_dns_name"] # No trailing period
  index_page        = each.value["index_page"]
  project_id        = var.project_id
  region            = var.region
  managed_zone_name = module.managed_zone.managed_zone_name
}
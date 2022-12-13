locals {
  service_account_full_name = "${var.service_account_user_name}@${var.project_id}.iam.gserviceaccount.com"
}

resource "google_iam_workload_identity_pool" "github-workload-identity-pool" {
  project                   = var.project_id
  workload_identity_pool_id = "${var.github_action_name}-workload-identity-pool"
}

resource "google_iam_workload_identity_pool_provider" "github-workload-identity-pool-provider" {
  workload_identity_pool_id          = google_iam_workload_identity_pool.github-workload-identity-pool.workload_identity_pool_id
  workload_identity_pool_provider_id = "${var.github_action_name}-workload-identity-pool-provider"
  attribute_mapping                  = {
    "google.subject"             = "assertion.sub"
    "attribute.actor"            = "assertion.actor"
    "attribute.aud"              = "assertion.aud",
    "attribute.repository_owner" = "assertion.repository_owner"
  }
  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

resource "google_service_account" "sa" {
  account_id   = local.service_account_full_name
  display_name = "The github action service account"
}

data "google_iam_policy" "admin" {
  binding {
    role = "roles/storage.objectAdmin"

    members = [
      "serviceAccount:${service_account_full_name}",
    ]
  }

  binding {
    role = "roles/storage.serviceAccountOpenIdTokenCreator"

    members = [
      "serviceAccount:${service_account_full_name}",
    ]
  }
}

resource "google_service_account_iam_binding" "github-service-account-iam" {
  service_account_id = google_service_account.sa.name
  role               = "roles/iam.workloadIdentityUser"

  members = [
    "principalSet://iam.googleapis.com/${google_iam_workload_identity_pool.github-workload-identity-pool.workload_identity_pool_id}/attribute.repository_owner/${var.org_name}"
  ]
}


resource "google_service_account" "karpenter_wif" {
  account_id = "karpenter-system-sa"
}

resource "google_project_iam_member" "compute" {
  member  = format("serviceAccount:%s@%s.iam.gserviceaccount.com", google_service_account.karpenter_wif.account_id, data.google_client_config.default.project)
  project = data.google_client_config.default.project
  role    = "roles/compute.admin"
}

resource "google_project_iam_member" "container" {
  member  = format("serviceAccount:%s@%s.iam.gserviceaccount.com", google_service_account.karpenter_wif.account_id, data.google_client_config.default.project)
  project = data.google_client_config.default.project
  role    = "roles/container.admin"
}

resource "google_project_iam_member" "iam" {
  member  = format("serviceAccount:%s@%s.iam.gserviceaccount.com", google_service_account.karpenter_wif.account_id, data.google_client_config.default.project)
  project = data.google_client_config.default.project
  role    = "roles/iam.serviceAccountUser"
}

# GKE creates WIF pool and adds the cluster as WIF provider when WIF enabled on GKE
# this bit is all you need to allow impresonating GSA
resource "google_service_account_iam_member" "name" {
  member             = "serviceAccount:${data.google_client_config.default.project}.svc.id.goog[karpenter-system/karpenter]"
  role               = "roles/iam.workloadIdentityUser"
  service_account_id = google_service_account.karpenter_wif.id
}

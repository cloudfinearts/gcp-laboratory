variable "cluster_name" {
  type = string
}

variable "nodes" {
  type    = number
  default = 3
}

locals {
  # nasty! google_client_config has "zone" empty when not set in the provider 
  zone = data.google_compute_zones.this.names[0]
}

data "google_client_config" "this" {
}

data "google_compute_zones" "this" {
}

resource "google_service_account" "this" {
  account_id = "${var.cluster_name}-gke-sa"
}

resource "google_container_cluster" "this" {
  name = var.cluster_name

  # deleting & creating indendent node pool takes time
  # remove_default_node_pool = true
  initial_node_count = var.nodes

  # set region to create regional cluster with node per a zone
  location = local.zone

  workload_identity_config {
    workload_pool = "${data.google_client_config.this.project}.svc.id.goog"
  }

  # private cluster requires Cloud NAT for pods to download images etc.
  # private_cluster_config {
  #   # do not allocate public IP
  #   enable_private_nodes = true
  # }

  node_config {
    disk_size_gb = 20
    disk_type    = "pd-standard"
    preemptible  = true
    machine_type = "e2-standard-2"

    service_account = google_service_account.this.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      # got error in Workload Identity Federation without email scope
      # Unable to generate access token; IAM returned 403 Forbidden: Permission 'iam.serviceAccounts.getAccessToken' denied
      "https://www.googleapis.com/auth/userinfo.email"
    ]
  }

  # critical setting for updates
  deletion_protection = false
  #monitoring_service = "none"
}

# resource "google_container_node_pool" "this" {
#   cluster    = google_container_cluster.this.id
#   name       = "${var.cluster_name}-np"
#   location   = local.zone
#   node_count = var.nodes

#   node_config {
#     disk_size_gb = 20
#     disk_type    = "pd-standard"
#     preemptible  = true
#     machine_type = "e2-standard-2"

#     service_account = google_service_account.this.email
#     oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
#   }
# }

output "zone" {
  value = google_container_cluster.this.location
}

output "name" {
  value = var.cluster_name
}

provider "google" {
}

data "google_client_config" "default" {}

data "google_compute_zones" "this" {
}

resource "google_service_account" "worker" {
  account_id = "gke-worker-sa"
}

module "gke" {
  source                   = "terraform-google-modules/kubernetes-engine/google"
  project_id               = data.google_client_config.default.project
  name                     = "blueprints-gke-dev"
  region                   = data.google_client_config.default.region
  zones                    = slice(data.google_compute_zones.this.names, 0, 3)
  network                  = module.vpc.network_name
  subnetwork               = module.vpc.subnets_names[0]
  remove_default_node_pool = true

  # avoid IP_SPACE_EXHAUSTED_WITH_DETAILS
  # GKE allocates subnet slice from pod range to every node
  # max pods 110 (default) x 2 => /24 slice, pod range with /24 cidr will cause node pool timeout on creating 2nd node on exhausted IP space
  # e.g. range /18 will accomodate 64 /24 subnets for nodes, 24-18=6 bits
  ip_range_pods     = "${data.google_client_config.default.region}-gke-pods"
  ip_range_services = "${data.google_client_config.default.region}-gke-services"

  deletion_protection        = false
  http_load_balancing        = true
  horizontal_pod_autoscaling = true

  node_pools = [
    {
      name         = "karpenter-system-pool"
      machine_type = "e2-standard-2"
      # create node in each zone
      node_locations  = data.google_compute_zones.this.names[0]
      min_count       = 1
      max_count       = 4
      local_ssd_count = 0
      spot            = true
      disk_size_gb    = 20
      disk_type       = "pd-standard"
      image_type      = "COS_CONTAINERD"
      #   auto_repair     = true
      #   auto_upgrade    = true
      # no SA implies using default compute SA with full admin access
      service_account = google_service_account.worker.email
      # enable CA, default
      # autoscaling = true
    },
  ]

  node_pools_oauth_scopes = {
    all = [
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
    ]
  }

  node_pools_labels = {
    all = {}

    default-node-pool = {
      default-node-pool = true
    }
  }

  node_pools_metadata = {
    all = {}

    default-node-pool = {
      node-pool-metadata-custom-value = "my-node-pool"
    }
  }

  node_pools_taints = {
    all = []

    karpenter-system-pool = [
      {
        key    = "karpenter.sh/controller"
        value  = "true"
        effect = "NO_SCHEDULE"
      }
    ]

    default-node-pool = [
      {
        key    = "default-node-pool"
        value  = true
        effect = "PREFER_NO_SCHEDULE"
      },
    ]
  }

  node_pools_tags = {
    all = []

    default-node-pool = [
      "default-node-pool",
    ]
  }
}


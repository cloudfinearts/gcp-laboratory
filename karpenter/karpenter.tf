provider "helm" {
  kubernetes = {
    host                   = module.gke.endpoint
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke.ca_certificate)

    exec = {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
}

# gmp collector container created by karpenter uploads metrics to managed prom
resource "google_project_iam_member" "monitoring" {
  member  = google_service_account.worker.member
  project = data.google_client_config.default.project
  role    = "roles/monitoring.metricWriter"
}

# if chart fails, pull karpenter repo and get the latest chart
resource "helm_release" "karpenter" {
  namespace        = "karpenter-system"
  name             = "karpenter"
  create_namespace = true
  chart            = "${path.module}/charts/karpenter"
  wait             = false

  values = [
    <<-EOT
      # use WIF instead of SA key
      credentials:
          enabled: false
      serviceAccount:
          annotations:
              iam.gke.io/gcp-service-account: ${google_service_account.karpenter_wif.email}
      controller:
          settings:
              projectID: ${data.google_client_config.default.project}
              location: ${data.google_client_config.default.region}
              clusterName: ${module.gke.name}
          tolerations:
              - key: 'karpenter.sh/controller'
                operator: Equal
                value: "true"
                effect: NoSchedule
    EOT
  ]
}

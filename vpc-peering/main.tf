provider "google" {
  project = "bob-lab-320120"
}

locals {
  project = "ace-chapter9"
  region  = "europe-central2"
}

# (network) tags are meaningful only within VPC where firewal rule is defined
# peered VPCs are distinct networks
resource "google_compute_network_peering" "global" {
  name         = "peering-global-vpc"
  network      = google_compute_network.global.id
  peer_network = google_compute_network.main.id
}

resource "google_compute_network_peering" "local" {
  name         = "peering-local-vpc"
  network      = google_compute_network.main.id
  peer_network = google_compute_network.global.id
}

resource "google_dns_managed_zone" "main" {
  name = "${local.project}-private-zone"
  # trailing dot required
  dns_name   = "costa.com."
  visibility = "private"

  private_visibility_config {
    networks {
      network_url = google_compute_network.global.id
    }

    networks {
      network_url = google_compute_network.main.id
    }
  }
}

resource "google_dns_record_set" "warsaw" {
  name         = "warsaw.${google_dns_managed_zone.main.dns_name}"
  type         = "A"
  managed_zone = google_dns_managed_zone.main.name
  rrdatas      = [google_compute_instance.warsaw.network_interface[0].network_ip]
}

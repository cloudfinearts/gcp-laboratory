resource "google_compute_network" "main" {
  name                    = "${local.project}-vpc"
  auto_create_subnetworks = false
  // subnetwork can reside only in the region of a router
  routing_mode = "REGIONAL"
}

resource "google_compute_subnetwork" "main" {
  ip_cidr_range = "10.0.0.0/24"
  name          = "${local.project}-subnet"
  network       = google_compute_network.main.id
  stack_type    = "IPV4_ONLY"
  region        = local.region
}

resource "google_compute_firewall" "main" {
  name    = "allow-ssh-ping-rdp"
  network = google_compute_network.main.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  source_ranges = ["10.0.0.0/24", "10.0.1.0/24"]
}

data "google_compute_zones" "available" {
  region = local.region
}

resource "google_compute_instance" "main" {
  machine_type = local.machine_type
  name         = "${local.project}-local-vm"
  zone         = data.google_compute_zones.available.names[0]

  boot_disk {
    initialize_params {
      image = "rocky-linux-8-optimized-gcp"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.main.name
  }
}

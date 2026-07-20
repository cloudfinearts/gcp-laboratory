provider "google" {
  project = var.project
  zone    = "europe-central2-a"
  region  = "europe-central2"
}

terraform {
  required_version = "~>1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~>5.11"
    }
  }
}

resource "google_compute_firewall" "fw" {
  name    = "${var.app}-allow-http-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["80", "22"]
  }
  source_tags = ["lab"]
}

resource "google_compute_instance" "main" {
  name         = "${var.app}-vm"
  machine_type = var.machine_type

  boot_disk {
    initialize_params {
      image = var.image
    }
  }

  # network tag(s) to be targeted by firewall
  tags = ["lab"]

  network_interface {
    network = "default"

    # assign public ip address
    access_config {
    }
  }

  labels = {
    "app" = var.app
    # apply OS policy to install Ops agent for logging / metrics
    "goog-ops-agent-policy" = "v2-x86-template-1-1-0"
  }

  service_account {
    # default GCE SA, OS config agent cannot access metadata server without SA
    email  = "144911572436-compute@developer.gserviceaccount.com"
    scopes = ["cloud-platform"]
  }

  metadata = {
    # key from PPT file has incorrect format, Puttygen can show proper key
    "ssh-keys" = "${var.ssh_user}:${file("../../credentials/mykey.pub")}"
    # enable OS config agent of VM manager service
    "enable-osconfig"         = "TRUE"
    "enable-guest-attributes" = "TRUE"
  }
}

output "config" {
  value = {
    "public_ip" = google_compute_instance.main.network_interface.0.access_config.0.nat_ip
  }
}

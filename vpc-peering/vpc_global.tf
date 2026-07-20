resource "google_compute_network" "global" {
  name                    = "${local.project}-vpc-global"
  auto_create_subnetworks = false
  # AWS VPC is always regional
  routing_mode = "GLOBAL"
}

# AWS subnet spans over AZ whereas GCP subnet is regional
resource "google_compute_subnetwork" "warsaw" {
  ip_cidr_range = "10.0.1.0/24"
  name          = "${local.project}-subnet-warsaw"
  network       = google_compute_network.global.id
  stack_type    = "IPV4_ONLY"
  region        = "europe-central2"
}

resource "google_compute_subnetwork" "sydney" {
  ip_cidr_range = "10.0.2.0/24"
  name          = "${local.project}-subnet-sydney"
  network       = google_compute_network.global.id
  stack_type    = "IPV4_ONLY"
  region        = "australia-southeast1"

  # VPC flow logs 
  # log_config {
  #   aggregation_interval = "INTERVAL_5_SEC"
  #   flow_sampling        = 0.5
  #   metadata             = "INCLUDE_ALL_METADATA"
  # }
}

resource "google_compute_subnetwork" "vegas" {
  ip_cidr_range = "10.0.3.0/24"
  name          = "${local.project}-subnet-vegas"
  network       = google_compute_network.global.id
  stack_type    = "IPV4_ONLY"
  region        = "us-west4"
}

# AWS SG operates at resource level such as instance, RDS, GCP firewall is much simpler
resource "google_compute_firewall" "global" {
  name    = "allow-ssh-ping-rdp-global"
  network = google_compute_network.global.name

  allow {
    protocol = "icmp"
  }

  allow {
    protocol = "tcp"
    ports    = ["22", "3389"]
  }

  # applies to traffic between instances
  source_tags = ["global-vpc"]
  # applies to traffic to external IP address
  source_ranges = ["0.0.0.0/0"]

  # default target (egress) for the rule is either all instances or defined target tags/SA
}

locals {
  machine_type = "e2-medium"
}

data "google_compute_zones" "warsaw" {
  region = "europe-central2"
}

resource "google_compute_instance" "warsaw" {
  machine_type = local.machine_type
  name         = "${local.project}-warsaw-vm"
  zone         = data.google_compute_zones.warsaw.names[0]
  # aka network tag
  tags = ["global-vpc"]

  boot_disk {
    initialize_params {
      image = "rocky-linux-8-optimized-gcp"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.warsaw.name
    access_config {
    }
  }

  # ssh key comes from project metadata, Compute -> Settings -> Metadata
}

# resource "google_compute_instance" "sydney" {
#   machine_type = local.machine_type
#   name         = "${local.project}-sydney-vm"
#   zone         = "australia-southeast1-a"
#   tags         = ["global-vpc"]

#   boot_disk {
#     initialize_params {
#       image = "rocky-linux-8-optimized-gcp"
#     }
#   }

#   network_interface {
#     subnetwork = google_compute_subnetwork.sydney.name
#   }
# }

# resource "google_compute_instance" "vegas" {
#   machine_type = local.machine_type
#   name         = "${local.project}-vegas-vm"
#   zone         = "us-west4-a"
#   tags         = ["global-vpc"]

#   boot_disk {
#     initialize_params {
#       image = "rocky-linux-8-optimized-gcp"
#     }
#   }

#   network_interface {
#     subnetwork = google_compute_subnetwork.vegas.name
#   }
# }

output "config" {
  value = {
    warsaw = google_compute_instance.warsaw.network_interface.0.access_config.0.nat_ip
  }
}

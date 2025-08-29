module "vpc" {
  source  = "terraform-google-modules/network/google"
  version = "~> 11.1"

  project_id   = data.google_client_config.default.project
  network_name = "gke-vpc"

  subnets = [
    {
      subnet_name   = "gke-subnet-1"
      subnet_ip     = "10.0.1.0/24"
      subnet_region = data.google_client_config.default.region
    },
  ]

  # create secondary IP ranges to separate VM and pod traffic
  # alias IP range is a slice of IP address from primary / secondary assigned to a resource
  secondary_ranges = {
    gke-subnet-1 = [
      {
        range_name    = "${data.google_client_config.default.region}-gke-pods"
        ip_cidr_range = "192.168.64.0/18"
      },
      {
        range_name    = "${data.google_client_config.default.region}-gke-services"
        ip_cidr_range = "192.168.128.0/18"
      },
    ]
  }

  # default-internet-gateway is a virtual next-hop device assigned to the route to the internet, no IGW to manage
  #   routes = [
  #     {
  #       name              = "egress-internet"
  #       description       = "route through IGW to access internet"
  #       destination_range = "0.0.0.0/0"
  #       tags              = "egress-inet"
  #       next_hop_internet = "true"
  #     },
  #   ]
}

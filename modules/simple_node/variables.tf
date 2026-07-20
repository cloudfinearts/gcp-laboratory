variable "app" {
  default = "lab"
}

variable "project" {
  default = "bob-lab-320120"
}

variable "ssh_user" {
  default = "bob"
}

variable "image" {
  # default = "centos-7"
  default = "ubuntu-2204-lts"
}

variable "machine_type" {
  default = "e2-medium"
}

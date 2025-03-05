data "google_project" "project" {
  depends_on = [
    module.project_services
  ]

  project_id = var.project_id
}

resource "random_id" "deployment" {
  byte_length = 8
}

locals {
  ssh_user             = "dev"
  private_key_filename = "${random_id.deployment.hex}_ansible_gcp"
  public_key_filename  = "${random_id.deployment.hex}_ansible_gcp.pub"
}

resource "google_service_account" "auction" {
  project    = data.google_project.project.project_id
  account_id = "auction-${random_id.deployment.hex}"
}

resource "google_project_iam_member" "auction" {
  for_each = toset([
    "roles/compute.admin",
    "roles/iam.serviceAccountUser",
  ])

  project = data.google_project.project.project_id
  role    = each.key
  member  = "serviceAccount:${google_service_account.auction.email}"
}

module "global_addresses" {
  source = "terraform-google-modules/address/google"

  project_id   = data.google_project.project.project_id
  region       = var.region
  address_type = "EXTERNAL"
  names = [
    "grafana",
  ]
}

resource "google_compute_network" "auction" {
  project                 = data.google_project.project.project_id
  name                    = "auction-${random_id.deployment.hex}"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "auction" {
  name          = "auction-${random_id.deployment.hex}"
  network       = google_compute_network.auction.id
  region        = var.region
  ip_cidr_range = "10.2.0.0/16"
}

resource "google_compute_firewall" "auction_ssh" {
  project = data.google_project.project.project_id
  name    = "auction-${random_id.deployment.hex}-ssh"
  network = google_compute_network.auction.self_link

  allow {
    protocol = "tcp"
    ports = [
      22,
    ]
  }

  source_ranges = [
    "35.235.240.0/20",  # IAP TCP forwarding IP range.
    "0.0.0.0/0"
  ]
}

resource "google_compute_firewall" "grafana" {
  project = data.google_project.project.project_id
  name    = "grafana-${random_id.deployment.hex}"
  network = google_compute_network.auction.self_link

  allow {
    protocol = "tcp"
    ports = [
      3000,
    ]
  }

  source_ranges = [
    "0.0.0.0/0",
  ]

  target_tags = ["grafana"]
}

resource "google_compute_firewall" "nginx" {
  project = data.google_project.project.project_id
  name    = "nginx-${random_id.deployment.hex}"
  network = google_compute_network.auction.self_link

  allow {
    protocol = "tcp"
    ports = [
      80,
    ]
  }

  source_ranges = [
    "0.0.0.0/0",
  ]

  target_tags = ["nginx"]
}

resource "tls_private_key" "auction" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "private_key" {
  content         = tls_private_key.auction.private_key_pem
  filename        = pathexpand("~/.ssh/${local.private_key_filename}")
  file_permission = "0600"
}

resource "local_file" "public_key" {
  content         = tls_private_key.auction.public_key_openssh
  filename        = pathexpand("~/.ssh/${local.public_key_filename}")
  file_permission = "0600"
}

resource "google_compute_instance" "auction" {
  project = data.google_project.project.project_id

  name         = "auction-${random_id.deployment.hex}"
  zone         = var.zone
  machine_type = "e2-small"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.auction.id
    access_config {
      nat_ip = module.global_addresses.addresses[0]
    }
  }

  service_account {
    email  = google_service_account.auction.email
    scopes = ["cloud-platform"]
  }

  tags = [
    "grafana",
    "nginx",
  ]

  metadata = {
    ssh-keys = "${local.ssh_user}:${local_file.public_key.content}"
  }
}
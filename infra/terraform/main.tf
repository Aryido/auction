data "google_project" "project" {
  depends_on = [
    module.project_services
  ]

  project_id = var.project_id
}

resource "google_service_account" "auction" {
  project    = data.google_project.project.project_id
  account_id = "auction-sa"
}

resource "google_project_iam_member" "auction" {
  for_each = toset([
    "roles/compute.admin",
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
  name                    = "auction"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "auction" {
  name          = "auction"
  network       = google_compute_network.auction.id
  region        = var.region
  ip_cidr_range = "10.2.0.0/16"
}


resource "google_compute_firewall" "auction_ssh" {
  project = data.google_project.project.project_id
  name    = "auction-ssh"
  network = google_compute_network.auction.self_link

  allow {
    protocol = "tcp"
    ports = [
      22,
    ]
  }

  # IAP TCP forwarding IP range.
  source_ranges = [
    "35.235.240.0/20",
  ]
}

resource "google_compute_firewall" "grafana" {
  project = data.google_project.project.project_id
  name    = "grafana"
  network = google_compute_network.auction.self_link

  allow {
    protocol = "tcp"
    ports = [
      3000,
    ]
  }

  source_ranges = [
    "0.0.0.0/0",
    #module.global_addresses.addresses[0] # ???
  ]
  target_tags = ["grafana"]
}

resource "google_compute_instance" "auction" {
  project = data.google_project.project.project_id

  name         = "auction"
  zone         = var.zone
  machine_type = "e2-small"

  boot_disk {
    initialize_params {
      image = "projects/cos-cloud/global/images/family/cos-stable"
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.auction.id
    access_config {
      nat_ip = module.global_addresses.addresses[0]
    }
  }

  tags = ["grafana"]

  service_account {
    email  = google_service_account.auction.email
    scopes = ["cloud-platform"]
  }
}

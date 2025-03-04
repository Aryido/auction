terraform {
  required_version = "1.10.5"

  backend "gcs" {
    bucket  = "decisive-post-452103-s7-tf-state"
    prefix  = "terraform/state"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.22.0"
    }

    random = {
      source = "hashicorp/random"
      version = "3.7.1"
    }

    tls = {
      source = "hashicorp/tls"
      version = "4.0.6"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

provider "random" {
}

provider "tls" {
}
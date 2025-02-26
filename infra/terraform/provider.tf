terraform {
  required_version = "1.10.5"

  backend "gcs" {
    bucket = "<YOUR-GCS-BUCKET-NAME>"
    prefix = "<YOUR-GCS-BUCKET-PATH>"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.22.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

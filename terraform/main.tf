terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "ev-elt"
  region  = "us-east4"
}

resource "google_storage_bucket" "raw_data" {
  name     = "flight-pipeline-raw-data"
  location = "US"

  uniform_bucket_level_access = true

  lifecycle_rule {
    action {
      type = "Delete"
    }
    condition {
      age = 90
    }
  }
}

resource "google_bigquery_dataset" "flights" {
  dataset_id = "flight_pipeline"
  location   = "US"
}

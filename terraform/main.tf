terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "ev-elt"
  region  = "us-east4"
}

provider "google-beta" {
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

# === Datasets per layer ===

resource "google_bigquery_dataset" "bronze" {
  dataset_id = "bronze"
  location   = "US"
}

resource "google_bigquery_dataset" "silver" {
  dataset_id = "silver"
  location   = "US"
}

resource "google_bigquery_dataset" "gold" {
  dataset_id = "gold"
  location   = "US"
}

# === External tables in BigQuery ===

resource "google_bigquery_table" "bronze_business" {
  dataset_id          = google_bigquery_dataset.bronze.dataset_id
  table_id            = "business"
  deletion_protection = false

  external_data_configuration {
    source_format = "CSV"
    autodetect    = true
    source_uris   = ["gs://${google_storage_bucket.raw_data.name}/bronze/business.csv"]
  }
}

resource "google_bigquery_table" "bronze_economy" {
  dataset_id          = google_bigquery_dataset.bronze.dataset_id
  table_id            = "economy"
  deletion_protection = false

  external_data_configuration {
    source_format = "CSV"
    autodetect    = true
    source_uris   = ["gs://${google_storage_bucket.raw_data.name}/bronze/economy.csv"]
  }
}

# === Dataform config ===

resource "google_dataform_repository" "pipeline" {
  provider = google-beta
  name     = "flight_pipeline"
  region   = "us-east4"
}

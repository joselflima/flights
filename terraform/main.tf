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

# === GitHub PAT for Dataform git remote ===
# References the existing GITHUB_PAT secret already in Secret Manager.
# Terraform never reads or stores the token value, only its version reference.

data "google_secret_manager_secret_version" "github_pat" {
  secret = "GITHUB_PAT"
}

# Allow the Dataform service agent to read the PAT at sync time.
data "google_project" "this" {}

resource "google_secret_manager_secret_iam_member" "dataform_access" {
  secret_id = "GITHUB_PAT"
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:service-${data.google_project.this.number}@gcp-sa-dataform.iam.gserviceaccount.com"
}

# === Dataform config ===

resource "google_dataform_repository" "pipeline" {
  provider = google-beta
  name     = "flight_pipeline"
  region   = "us-east4"

  git_remote_settings {
    url                                 = "https://github.com/joselflima/flights.git"
    default_branch                      = "main"
    authentication_token_secret_version = data.google_secret_manager_secret_version.github_pat.id
  }
}

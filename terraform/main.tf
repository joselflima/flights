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
# Raw CSVs share one schema; kept all-STRING and typed later in the silver layer.

locals {
  flights_schema = jsonencode([
    { name = "date", type = "STRING" },
    { name = "airline", type = "STRING" },
    { name = "ch_code", type = "STRING" },
    { name = "num_code", type = "STRING" },
    { name = "dep_time", type = "STRING" },
    { name = "from", type = "STRING" },
    { name = "time_taken", type = "STRING" },
    { name = "stop", type = "STRING" },
    { name = "arr_time", type = "STRING" },
    { name = "to", type = "STRING" },
    { name = "price", type = "STRING" },
  ])
}

resource "google_bigquery_table" "bronze_business" {
  dataset_id          = google_bigquery_dataset.bronze.dataset_id
  table_id            = "business"
  deletion_protection = false
  schema              = local.flights_schema

  external_data_configuration {
    source_format = "CSV"
    autodetect    = false
    source_uris   = ["gs://${google_storage_bucket.raw_data.name}/bronze/business.csv"]

    csv_options {
      quote                 = "\""
      skip_leading_rows     = 1
      allow_quoted_newlines = true
    }
  }
}

resource "google_bigquery_table" "bronze_economy" {
  dataset_id          = google_bigquery_dataset.bronze.dataset_id
  table_id            = "economy"
  deletion_protection = false
  schema              = local.flights_schema

  external_data_configuration {
    source_format = "CSV"
    autodetect    = false
    source_uris   = ["gs://${google_storage_bucket.raw_data.name}/bronze/economy.csv"]

    csv_options {
      quote                 = "\""
      skip_leading_rows     = 1
      allow_quoted_newlines = true
    }
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

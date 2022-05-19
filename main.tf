// set GCP as provider
provider "google" {
  credentials = file("/Users/szombatiattila/.config/gcloud/application_default_credentials.json")

  project = "attila-szombati-sandbox"
  region  = "us-central1"
}

// use GCS to store terraform state
resource "google_storage_bucket" "default" {
  name          = "attila-szombati-sandbox-tfstate"
  force_destroy = false
  location      = "US"
  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
}

// Initialize BQ dataset
resource "google_bigquery_dataset" "dataset" {
  dataset_id = "terraform_dataset"
}

// output as a sensitive data
output "cloud-sql-postgres-password" {
  value     = google_sql_database_instance.main.root_password
  sensitive = true
}

output "cloud-sql-postgres-public-ip" {
  value = google_sql_database_instance.main.public_ip_address
}

// get input variable for VM instance type or use the staging.tfvars var file
variable "tier" {
  type = string
}
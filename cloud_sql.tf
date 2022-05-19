resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

// create Cloud SQL instance with the given parameters
resource "google_sql_database_instance" "main" {
  name                = "cloud-db-12345"
  database_version    = "POSTGRES_13"
  region              = "us-central1"
  root_password       = random_password.password.result
  deletion_protection = false

  settings {
    tier = var.tier

  }
}

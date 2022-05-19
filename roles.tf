// create service account SVC
resource "google_service_account" "SVC" {
  account_id   = "dataset"
  display_name = "Service Account for dataset"
}

// save ssh private key pem on local machine
resource "local_sensitive_file" "sa_private_key" {
  content         = base64decode(google_service_account_key.mykey.private_key)
  filename        = "./sa_private_key.json"
  file_permission = "0600"
}

resource "google_service_account_key" "mykey" {
  service_account_id = google_service_account.SVC.name
}

resource "google_project_iam_binding" "bigquery_user" {
  project = "attila-szombati-sandbox"
  role    = "roles/bigquery.user"

  members = [
    "serviceAccount:${google_service_account.SVC.email}",
  ]

}
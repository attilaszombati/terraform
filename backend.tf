terraform {
  backend "gcs" {
    bucket      = "attila-szombati-sandbox-tfstate"
    prefix      = "terraform/state"
    credentials = "/Users/szombatiattila/.config/gcloud/application_default_credentials.json"
  }
}
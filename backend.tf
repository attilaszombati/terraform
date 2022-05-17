terraform {
  backend "gcs" {
    bucket      = "attila-szombati-sandbox-bucket-tfstate"
    prefix      = "terraform/state"
    credentials = "attila-szombati-sandbox-922065a81037.json"
  }
}
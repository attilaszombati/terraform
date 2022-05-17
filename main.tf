// set GCP as provider
provider "google" {
  credentials = file("attila-szombati-sandbox-922065a81037.json")

  project = "attila-szombati-sandbox"
  region  = "us-central1"
  zone    = "us-central1-c"
}

// use GCS to store terraform state
resource "google_storage_bucket" "default" {
  name          = "attila-szombati-sandbox-bucket-tfstate"
  force_destroy = false
  location      = "US"
  storage_class = "STANDARD"
  versioning {
    enabled = true
  }
}

// create service account SVC
resource "google_service_account" "SVC" {
  account_id   = "dataset"
  display_name = "Service Account for dataset"
}

// save ssh private key pem on local machine
resource "local_sensitive_file" "ssh_private_key_pem" {
  content         = base64decode(google_service_account_key.mykey.private_key)
  filename        = "./sa_private_key.json"
  file_permission = "0600"
}

resource "google_service_account_key" "mykey" {
  service_account_id = google_service_account.SVC.name
}


// WIP part
data "google_iam_policy" "admin" {

  binding {
    role = "roles/iam.serviceAccountUser"

    members = [
      "user:attila.szombati@aliz.ai",
      "serviceAccount:${google_service_account.SVC.email}",
    ]
  }
}

// WIP part
resource "google_project_iam_policy" "project" {
  project     = "attila-szombati-sandbox"
  policy_data = data.google_iam_policy.admin.policy_data
}

// Initialize BQ dataset
resource "google_bigquery_dataset" "dataset" {
  dataset_id = "terraform_dataset"
}

// create VPC network
resource "google_compute_network" "vpc_network" {
  name = "terraform-network"
}

provider "tls" {
  // no config needed
}


// allow SSH to Compute engine instance
resource "tls_private_key" "ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "ssh_private_key_pem" {
  content         = tls_private_key.ssh.private_key_pem
  filename        = ".ssh/google_compute_engine"
  file_permission = "0600"
}

resource "google_compute_firewall" "allow_ssh" {
  name          = "allow-ssh"
  network       = google_compute_network.vpc_network.name
  target_tags   = ["allow-ssh"] // this targets our tagged VM
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

resource "google_compute_address" "static_ip" {
  name = "debian-vm"
}

// create Compute engine instance with the given parameters
resource "google_compute_instance" "vm_instance" {
  name                      = "computer-123d"
  machine_type              = "n2-standard-2"
  allow_stopping_for_update = true
  tags                      = ["allow-ssh"] // this receives the firewall rule

  metadata = {
    ssh-keys = "${split("@", google_service_account.SVC.email)[0]}:${tls_private_key.ssh.public_key_openssh}"
  }

  service_account {
    email  = google_service_account.SVC.email
    scopes = ["bigquery"]
  }

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-9"
    }
  }

  network_interface {
    network = google_compute_network.vpc_network.name
    access_config {
      nat_ip = google_compute_address.static_ip.address
    }
  }
}

resource "random_id" "instance_id" {
  byte_length = 8
}

// create Cloud SQL instance with the given parameters
resource "google_sql_database_instance" "main" {
  name             = "cloud-sql-postgres"
  database_version = "POSTGRES_13"
  region           = "us-central1"
  root_password    = random_id.instance_id.hex

  settings {
    tier = var.tier

  }
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
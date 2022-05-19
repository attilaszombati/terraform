resource "google_compute_address" "static_ip" {
  name = "debian-vm"
}

// create Compute engine instance with the given parameters
resource "google_compute_instance" "vm_instance" {
  zone                      = "us-central1-c"
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
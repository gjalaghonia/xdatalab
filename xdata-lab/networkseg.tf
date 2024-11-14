resource "google_compute_global_network_endpoint_group" "private_bucket_neg" {
  name                  = "${var.prefix}-neg"
  project               = var.project_id
  network_endpoint_type = "INTERNET_FQDN_PORT"
  default_port          = 443
}

resource "google_compute_global_network_endpoint" "private_bucket_ne" {
  global_network_endpoint_group = google_compute_global_network_endpoint_group.private_bucket_neg.id
  fqdn                          = "${google_storage_bucket.private_bucket.name}.storage.googleapis.com"
  port                          = 443
}
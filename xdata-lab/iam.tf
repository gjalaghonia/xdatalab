resource "google_service_account" "private_bucket_sa" {
  project      = var.project_id
  account_id   = "${var.prefix}-private-gcs-sa"
  display_name = "Service Account for private bucket"
}

resource "google_storage_bucket_iam_member" "private_bucket_member" {
  bucket     = google_storage_bucket.private_bucket.name
  role       = "roles/storage.objectViewer"
  member     = "serviceAccount:${google_service_account.private_bucket_sa.email}"
  depends_on = [google_storage_bucket.private_bucket]
}
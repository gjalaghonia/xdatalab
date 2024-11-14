resource "google_storage_bucket" "private_bucket" {
  name                        = var.bucket_name
  location                    = var.region
  storage_class               = "STANDARD"
  public_access_prevention    = "enforced"
  uniform_bucket_level_access = true

  versioning {
    enabled = var.enable_bucket_versioning
  }

}

resource "google_storage_hmac_key" "private_bucket_hmac_key" {
  project               = var.project_id
  service_account_email = google_service_account.private_bucket_sa.email
}
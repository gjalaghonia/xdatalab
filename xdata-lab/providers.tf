terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = ">=5.42.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = ">=5.42.0"
    }
    # null = {
    #   source  = "hashicorp/null"
    #   version = "3.2.2"
    # }
  }
    backend "gcs" {
    bucket = {}
    prefix = {}
  }
}
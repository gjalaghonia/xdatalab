resource "google_compute_global_address" "alb_global_address" {
  count        = var.create_global_address ? 1 : 0
  project      = var.project_id
  name         = "${var.prefix}-alb-global-adress"
  address_type = "EXTERNAL"
}

resource "google_compute_global_forwarding_rule" "alb_forwarding_rule_https" {
  project               = var.project_id
  name                  = "${var.prefix}-alb-forwarding-rule-https"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "443"
  target                = google_compute_target_https_proxy.alb_https_target_proxy.id
  ip_address            = local.address
}

resource "google_compute_global_forwarding_rule" "alb_forwarding_rule_http" {
  project               = var.project_id
  name                  = "${var.prefix}-alb-forwarding-rule-http"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  port_range            = "80"
  target                = google_compute_target_http_proxy.alb_http_target_proxy.id
  ip_address            = local.address
}

resource "google_compute_url_map" "https_redirect_url_map" {
  project = var.project_id
  name    = "${var.prefix}-https-redirect-url-map"
  default_url_redirect {
    https_redirect         = true
    strip_query            = false
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
  }
}

resource "google_compute_url_map" "alb_url_map" {
  project         = var.project_id
  name            = "${var.prefix}-alb-url-map"
  default_service = google_compute_backend_service.private_bucket_backend_svc.id

  header_action {
    request_headers_to_remove = ["Cookie"]
  }
}

resource "google_compute_target_http_proxy" "alb_http_target_proxy" {
  project = var.project_id
  name    = "${var.prefix}-alb-http-target-proxy"
  url_map = google_compute_url_map.https_redirect_url_map.id

}


resource "google_compute_target_https_proxy" "alb_https_target_proxy" {
  project          = var.project_id
  name             = "${var.prefix}-alb-https-target-proxy"
  url_map          = google_compute_url_map.alb_url_map.id
  ssl_certificates = var.create_certs ? [google_compute_managed_ssl_certificate.alb_managed_cert[0].id] : [google_compute_ssl_certificate.self_signed_cert[0].id]
}

resource "google_compute_backend_service" "private_bucket_backend_svc" {
  project               = var.project_id
  name                  = "${var.prefix}-private-bucket-backend-svc"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  protocol              = "HTTPS"
  enable_cdn            = true

  custom_request_headers = [
    "host: ${google_compute_global_network_endpoint.private_bucket_ne.fqdn}"
  ]

  backend {
    group = google_compute_global_network_endpoint_group.private_bucket_neg.id
  }

  security_settings {
    aws_v4_authentication {
      access_key_id      = google_storage_hmac_key.private_bucket_hmac_key.access_id
      access_key         = google_storage_hmac_key.private_bucket_hmac_key.secret
      access_key_version = var.access_key_version
      origin_region      = var.region
    }
  }
}

# data "google_dns_managed_zone" "dns_zone" {
#   project = var.project_id
#   name    = var.dns_zone
# }

# provider "google" {
#   project = var.project_id
#   region  = var.region
# }

# data "google_project" "project" {}

resource "google_dns_managed_zone" "dns_zone" {
  name        = var.dns_zone
  dns_name    = "${var.domain_name}."
  description = " DNS zone with some Dns Name"
}


resource "google_dns_record_set" "lb_a_record" {
  count        = var.create_dns_record ? 1 : 0
  project      = var.project_id
  name         = "${var.prefix}.${google_dns_managed_zone.dns_zone.dns_name}"
  managed_zone = google_dns_managed_zone.dns_zone.name
  type         = "A"
  ttl          = 300
  rrdatas      = [google_compute_global_address.alb_global_address[0].address]
}
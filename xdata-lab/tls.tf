resource "google_compute_managed_ssl_certificate" "alb_managed_cert" {
  count   = var.create_certs ? 1 : 0
  project = var.project_id
  name    = "${var.prefix}-managed-alb-certs"

  managed {
    domains = [local.domain_name]
  }
}


### FOR TESTING PURPOSE!!!!!!!!! NOT RECOMENDED HARD_CODED
resource "google_compute_ssl_certificate" "self_signed_cert" {
  count       = var.create_certs == false ? 1 : 0
  project     = var.project_id
  name        = "${var.prefix}-selfsigned-certs"
  description = "Self Signed certs for the ALB"
  private_key = file("./cert/tf-xdatalab1t.net.key")  ### can generate by openssl , in real case above managed are use always
  certificate = file("./cert/tf-xdatalab1t.net.crt")
}
locals {
  address     = var.create_global_address ? join("", google_compute_global_address.alb_global_address[*].address) : var.global_address
  temp_domain = var.create_dns_record ? "${var.prefix}.${google_dns_managed_zone.dns_zone.dns_name}" : ""
  domain_name = var.create_dns_record ? join("", [local.temp_domain]) : var.domain_name
}
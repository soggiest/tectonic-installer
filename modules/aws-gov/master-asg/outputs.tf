output "ingress_external_fqdn" {
  value = "${join(" ", powerdns_record.ingress_public.*.name)}"
}

output "ingress_internal_fqdn" {
  value = "${join(" ", powerdns_record.ingress_private.*.name)}"
}

output "api_external_fqdn" {
  value = "${join(" ", powerdns_record.api_external.*.name)}"
}

output "api_internal_fqdn" {
  value = "${join(" ", powerdns_record.api_internal.*.name)}"
}

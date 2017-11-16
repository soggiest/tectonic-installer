output "ingress_external_fqdn" {
  value = "${replace(replace(join(";", powerdns_record.ingress_public.*.name), "/[.];/", " "), "/[.]$/", "")}"  
#  value = "${powerdns_record.ingress_public.name}"  
  # value = "${join(" ", powerdns_record.ingress_public.*.name)}"
}

output "ingress_internal_fqdn" {
  value = "${replace(replace(join(";", powerdns_record.ingress_public.*.name), "/[.];/", " "), "/[.]$/", "")}"
#  value = "${powerdns_record.ingress_private.name}"  
  # value = "${join(" ", powerdns_record.ingress_private.*.name)}"
}

output "api_external_fqdn" {
   value = "${replace(replace(join(";", powerdns_record.ingress_public.*.name), "/[.];/", " "), "/[.]$/", "")}"
  value = "${replace(join(";", powerdns_record.api_external.*.name), "/[.];/", " ")}"
  # value = "${join(" ", powerdns_record.api_external.*.name)}"
}

output "api_internal_fqdn" {
    value = "${replace(replace(join(";", powerdns_record.ingress_public.*.name), "/[.];/", " "), "/[.]$/", "")}"
  # value = "${powerdns_record.api_internal.name}${powerdns_record.ingress_public.zone}"
  # value = "${join(" ", powerdns_record.api_internal.*.name)}"
}

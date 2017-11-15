# We have to do this join() & split() 'trick' because the ternary operator can't output lists.
output "endpoints" {
  value = ["${split(",", length(var.external_endpoints) == 0 ? join(",", powerdns_record.etc_a_nodes.*.name) : join(",", var.external_endpoints))}"]
}

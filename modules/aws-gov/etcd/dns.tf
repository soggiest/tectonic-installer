resource "powerdns_record" "etcd_srv_discover" {
  count   = "${var.dns_enabled ? 1 : 0}"
  name    = "${var.tls_enabled ? "_etcd-server-ssl._tcp.${var.base_domain}." : "_etcd-server._tcp.${var.base_domain}."}"
  type    = "SRV"
  zone    = "${var.base_domain}"
  records = ["${formatlist("0 0 2380 %s", powerdns_record.etc_a_nodes.*.name)}"]
  ttl     = "300"
}

resource "powerdns_record" "etcd_srv_client" {
  count   = "${var.dns_enabled ? 1 : 0}"
  name    = "${var.tls_enabled ? "_etcd-client-ssl._tcp.${var.base_domain}." : "_etcd-client._tcp.${var.base_domain}."}"
  type    = "SRV"
  zone    = "${var.base_domain}"
  records = ["${formatlist("0 0 2379 %s", powerdns_record.etc_a_nodes.*.name)}"]
  ttl     = "60"
}

resource "powerdns_record" "etc_a_nodes" {
  count   = "${var.dns_enabled ? var.instance_count : 0}"
  type    = "A"
  ttl     = "60"
  zone    = "${var.base_domain}"
  name    = "${var.cluster_name}-etcd-${count.index}.${var.base_domain}."
  records = ["${aws_instance.etcd_node.*.private_ip[count.index]}"]
}

resource "aws_eip" "powerdns_endpoint" {
  count = "${var.external_dns == "true" ? 1: 0}"
  vpc   = true
}

resource "aws_eip_association" "eip_assoc" {
  count = "${var.external_dns == "true" ? 1: 0}"

  instance_id   = "${aws_instance.powerdns_node.id}"
  allocation_id = "${aws_eip.powerdns_endpoint.id}"
}

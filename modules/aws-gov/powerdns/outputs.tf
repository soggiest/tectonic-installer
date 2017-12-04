output "server_ip" {
  value = "${var.external_dns ? aws_eip.powerdns_endpoint.public_ip : aws_instance.powerdns_node.*.private_ip[0]}"
}

data "template_file" "server_url" {
  template = "http://$${server_ip}:8081"

  vars {
    server_ip = "${var.external_dns ? aws_eip.powerdns_endpoint.public_ip : aws_instance.powerdns_node.*.private_ip[0]}"
  }
}

output "server_url" {
  value = "${data.template_file.server_url.rendered}"
}

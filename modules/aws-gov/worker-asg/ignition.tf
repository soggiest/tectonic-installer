data "ignition_config" "main" {
  files = [
    "${data.ignition_file.node_resolv}",
    "${var.ign_installer_kubelet_env_id}",
    "${var.ign_max_user_watches_id}",
    "${var.ign_s3_puller_id}",
  ]

  systemd = [
    "${var.ign_docker_dropin_id}",
    "${var.ign_k8s_node_bootstrap_service_id}",
    "${var.ign_kubelet_service_id}",
    "${var.ign_locksmithd_service_id}",
  ]
}

data "ignition_file" "node_resolv" {
  path       = "/etc/resolv.conf"
  mode       = 0644
  filesystem = "root"

  content {
    content = "nameserver ${aws_instance.powerdns_node.0.private_ip[0]}"
}


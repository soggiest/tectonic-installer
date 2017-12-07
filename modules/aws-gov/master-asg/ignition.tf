data "ignition_config" "main" {
  files = [
    "${data.ignition_file.detect_master.id}",
    "${data.ignition_file.init_assets.id}",
    "${var.ign_installer_kubelet_env_id}",
    "${var.ign_max_user_watches_id}",
    "${var.ign_s3_puller_id}",
    "${data.ignition_file.node_resolv.id}",
#    "${data.ignition_file.repository_cert.id}",
  ]

  systemd = ["${compact(list(
    var.ign_docker_dropin_id,
    var.ign_locksmithd_service_id,
    var.ign_kubelet_service_id,
    var.ign_k8s_node_bootstrap_service_id,
    data.ignition_systemd_unit.init_assets.id,
    var.ign_bootkube_service_id,
    var.ign_tectonic_service_id,
    var.ign_bootkube_path_unit_id,
    var.ign_tectonic_path_unit_id,
   ))}"]
}

data "ignition_file" "detect_master" {
  filesystem = "root"
  path       = "/opt/detect-master.sh"
  mode       = 0755

  content {
    content = "${file("${path.module}/resources/detect-master.sh")}"
  }
}

data "template_file" "node_resolv" {
  template = "nameserver ${var.nameserver_ip}"
}

data "ignition_file" "node_resolv" {
  path       = "/etc/resolv.conf"
  mode       = 0644
  filesystem = "root"

  content {
    content = "${data.template_file.node_resolv.rendered}"
  }
}

#data "ignition_file" "repository_cert" {
#  count      = "${var.quay_cert_path == "" ? 0 : 1}"
#  path       = "/etc/ssl/certs/custom-repository-ca.pem"
#  mode       = 0644
#  filesystem = "root"
#
#  content {
#    content = "${file(var.quay_cert_path)}"
#  }
#}


data "template_file" "init_assets" {
  template = "${file("${path.module}/resources/init-assets.sh")}"

  vars {
    cluster_name       = "${var.cluster_name}"
    awscli_image       = "${var.quay_hostname}${var.container_images["awscli"]}"
    assets_s3_location = "${var.assets_s3_location}"
    kubelet_image_url  = "${var.quay_hostname}${replace(var.container_images["hyperkube"],var.image_re,"$1")}"
    kubelet_image_tag  = "${var.quay_hostname}${replace(var.container_images["hyperkube"],var.image_re,"$2")}"
  }
}

data "ignition_file" "init_assets" {
  filesystem = "root"
  path       = "/opt/init-assets.sh"
  mode       = 0755

  content {
    content = "${data.template_file.init_assets.rendered}"
  }
}

data "ignition_systemd_unit" "init_assets" {
  name    = "init-assets.service"
  enable  = "${var.assets_s3_location != "" ? true : false}"
  content = "${file("${path.module}/resources/services/init-assets.service")}"
}

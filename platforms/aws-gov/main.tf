provider "aws" {
  region     = "${var.tectonic_aws_region}"
  version    = "0.1.4"
}

data "aws_availability_zones" "azs" {}

data "terraform_remote_state" "powerdns" {
  backend = "local"

  config {
    path = "../../build/dns-create/terraform.state"
  }
}

provider "powerdns" {
  version = "0.1.0"
  api_key = "tectonicgov"
  server_url = "${data.terraform_remote_state.powerdns.nameserver_url}"
}

module "etcd" {
  source = "../../modules/aws-gov/etcd"

  instance_count = "${var.tectonic_experimental ? 0 : var.tectonic_etcd_count > 0 ? var.tectonic_etcd_count : length(data.aws_availability_zones.azs.names) == 5 ? 5 : 3}"
  ec2_type       = "${var.tectonic_aws_etcd_ec2_type}"
  sg_ids         = "${concat(var.tectonic_aws_etcd_extra_sg_ids, list(data.terraform_remote_state.powerdns.etcd_sg_id))}"

  ssh_key         = "${var.tectonic_aws_ssh_key}"
  cl_channel      = "${var.tectonic_cl_channel}"
  container_image = "${var.tectonic_container_images["etcd"]}"

  subnets = "${data.terraform_remote_state.powerdns.worker_subnet_ids}"

# dns_zone_id  = "${var.tectonic_aws_private_endpoints ? data.null_data_source.zones.inputs["private"] : data.null_data_source.zones.inputs["public"]}"
  base_domain  = "${var.tectonic_base_domain}"
  cluster_name = "${var.tectonic_cluster_name}"

  external_endpoints = "${compact(var.tectonic_etcd_servers)}"
  cluster_id         = "${module.tectonic.cluster_id}"
  extra_tags         = "${var.tectonic_aws_extra_tags}"

  root_volume_type = "${var.tectonic_aws_etcd_root_volume_type}"
  root_volume_size = "${var.tectonic_aws_etcd_root_volume_size}"
  root_volume_iops = "${var.tectonic_aws_etcd_root_volume_iops}"

  dns_enabled = "${!var.tectonic_experimental && length(compact(var.tectonic_etcd_servers)) == 0}"
  tls_enabled = "${var.tectonic_etcd_tls_enabled}"

  tls_zip = "${module.etcd_certs.etcd_tls_zip}"
}

module "ignition_masters" {
  source = "../../modules/ignition"

  bootstrap_upgrade_cl = "${var.tectonic_bootstrap_upgrade_cl}"
  cloud_provider       = "aws"
  container_images     = "${var.tectonic_container_images}"
  image_re             = "${var.tectonic_image_re}"
  kube_dns_service_ip  = "${module.bootkube.kube_dns_service_ip}"
  kubeconfig_fetch_cmd = "/opt/s3-puller.sh ${aws_s3_bucket_object.kubeconfig.bucket}/${aws_s3_bucket_object.kubeconfig.key} /etc/kubernetes/kubeconfig"
  kubelet_cni_bin_dir  = "${var.tectonic_calico_network_policy ? "/var/lib/cni/bin" : "" }"
  kubelet_node_label   = "node-role.kubernetes.io/master"
  kubelet_node_taints  = "node-role.kubernetes.io/master=:NoSchedule"
  tectonic_vanilla_k8s = "${var.tectonic_vanilla_k8s}"
}

module "masters" {
  source = "../../modules/aws-gov/master-asg"

  api_sg_ids                   = ["${data.terraform_remote_state.powerdns.api_sg_id}"]
  assets_s3_location           = "${aws_s3_bucket_object.tectonic_assets.bucket}/${aws_s3_bucket_object.tectonic_assets.key}"
  autoscaling_group_extra_tags = "${var.tectonic_autoscaling_group_extra_tags}"
  base_domain                  = "${var.tectonic_base_domain}"
  cl_channel                   = "${var.tectonic_cl_channel}"
  cluster_id                   = "${module.tectonic.cluster_id}"
  cluster_name                 = "${var.tectonic_cluster_name}"
  console_sg_ids               = ["${data.terraform_remote_state.powerdns.console_sg_id}"]
  container_images             = "${var.tectonic_container_images}"
  custom_dns_name              = "${var.tectonic_dns_name}"
  ec2_type                     = "${var.tectonic_aws_master_ec2_type}"
# external_zone_id             = "${data.null_data_source.zones.inputs["public"]}"
  extra_tags                   = "${var.tectonic_aws_extra_tags}"
  image_re                     = "${var.tectonic_image_re}"
  instance_count               = "${var.tectonic_master_count}"
# internal_zone_id             = "${data.null_data_source.zones.inputs["private"]}"
  master_iam_role              = "${var.tectonic_aws_master_iam_role_name}"
  master_sg_ids                = "${concat(var.tectonic_aws_master_extra_sg_ids, list(data.terraform_remote_state.powerdns.master_sg_id))}"
  private_endpoints            = "${var.tectonic_aws_private_endpoints}"
  public_endpoints             = "${var.tectonic_aws_public_endpoints}"
  root_volume_iops             = "${var.tectonic_aws_master_root_volume_iops}"
  root_volume_size             = "${var.tectonic_aws_master_root_volume_size}"
  root_volume_type             = "${var.tectonic_aws_master_root_volume_type}"
  ssh_key                      = "${var.tectonic_aws_ssh_key}"
  subnet_ids                   = "${data.terraform_remote_state.powerdns.master_subnet_ids}"
  nameserver_ip                = "${data.terraform_remote_state.powerdns.nameserver_ip}"
  ign_bootkube_path_unit_id         = "${module.bootkube.systemd_path_unit_id}"
  ign_bootkube_service_id           = "${module.bootkube.systemd_service_id}"
  ign_docker_dropin_id              = "${module.ignition_masters.docker_dropin_id}"
  ign_installer_kubelet_env_id      = "${module.ignition_masters.installer_kubelet_env_id}"
  ign_k8s_node_bootstrap_service_id = "${module.ignition_masters.k8s_node_bootstrap_service_id}"
  ign_kubelet_service_id            = "${module.ignition_masters.kubelet_service_id}"
  ign_locksmithd_service_id         = "${module.ignition_masters.locksmithd_service_id}"
  ign_max_user_watches_id           = "${module.ignition_masters.max_user_watches_id}"
  ign_s3_puller_id                  = "${module.ignition_masters.s3_puller_id}"
  ign_tectonic_path_unit_id         = "${var.tectonic_vanilla_k8s ? "" : module.tectonic.systemd_path_unit_id}"
  ign_tectonic_service_id           = "${module.tectonic.systemd_service_id}"
}

module "ignition_workers" {
  source = "../../modules/ignition"

  bootstrap_upgrade_cl = "${var.tectonic_bootstrap_upgrade_cl}"
  cloud_provider       = "aws"
  container_images     = "${var.tectonic_container_images}"
  image_re             = "${var.tectonic_image_re}"
  kube_dns_service_ip  = "${module.bootkube.kube_dns_service_ip}"
  kubeconfig_fetch_cmd = "/opt/s3-puller.sh ${aws_s3_bucket_object.kubeconfig.bucket}/${aws_s3_bucket_object.kubeconfig.key} /etc/kubernetes/kubeconfig"
  kubelet_cni_bin_dir  = "${var.tectonic_calico_network_policy ? "/var/lib/cni/bin" : "" }"
  kubelet_node_label   = "node-role.kubernetes.io/node"
  kubelet_node_taints  = ""
  tectonic_vanilla_k8s = "${var.tectonic_vanilla_k8s}"
}

module "workers" {
  source = "../../modules/aws-gov/worker-asg"

  autoscaling_group_extra_tags = "${var.tectonic_autoscaling_group_extra_tags}"
  cl_channel                   = "${var.tectonic_cl_channel}"
  cluster_id                   = "${module.tectonic.cluster_id}"
  cluster_name                 = "${var.tectonic_cluster_name}"
  ec2_type                     = "${var.tectonic_aws_worker_ec2_type}"
  extra_tags                   = "${var.tectonic_aws_extra_tags}"
  instance_count               = "${var.tectonic_worker_count}"
  root_volume_iops             = "${var.tectonic_aws_worker_root_volume_iops}"
  root_volume_size             = "${var.tectonic_aws_worker_root_volume_size}"
  root_volume_type             = "${var.tectonic_aws_worker_root_volume_type}"
  sg_ids                       = "${concat(var.tectonic_aws_worker_extra_sg_ids, list(data.terraform_remote_state.powerdns.worker_sg_id))}"
  ssh_key                      = "${var.tectonic_aws_ssh_key}"
  subnet_ids                   = "${data.terraform_remote_state.powerdns.worker_subnet_ids}"
  vpc_id                       = "${data.terraform_remote_state.powerdns.vpc_id}"
  worker_iam_role              = "${var.tectonic_aws_worker_iam_role_name}"
  load_balancers               = ["${var.tectonic_aws_worker_load_balancers}"]
  nameserver_ip		       = "${data.terraform_remote_state.powerdns.nameserver_ip}"
  ign_docker_dropin_id              = "${module.ignition_workers.docker_dropin_id}"
  ign_installer_kubelet_env_id      = "${module.ignition_workers.installer_kubelet_env_id}"
  ign_k8s_node_bootstrap_service_id = "${module.ignition_workers.k8s_node_bootstrap_service_id}"
  ign_kubelet_service_id            = "${module.ignition_workers.kubelet_service_id}"
  ign_locksmithd_service_id         = "${module.ignition_masters.locksmithd_service_id}"
  ign_max_user_watches_id           = "${module.ignition_workers.max_user_watches_id}"
  ign_s3_puller_id                  = "${module.ignition_workers.s3_puller_id}"
}

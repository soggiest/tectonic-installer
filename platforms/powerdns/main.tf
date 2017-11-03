provider "aws" {
  region     = "${var.tectonic_aws_region}"
  version    = "0.1.4"
}


data "aws_availability_zones" "azs" {}

module "vpc" {
  source = "../../modules/aws-gov/vpc"

  cidr_block   = "${var.tectonic_aws_vpc_cidr_block}"
  base_domain  = "${var.tectonic_base_domain}"
  cluster_name = "${var.tectonic_cluster_name}"

  external_vpc_id         = "${var.tectonic_aws_external_vpc_id}"
  external_master_subnets = "${compact(var.tectonic_aws_external_master_subnet_ids)}"
  external_worker_subnets = "${compact(var.tectonic_aws_external_worker_subnet_ids)}"
  cluster_id              = "test1"
  extra_tags              = "${var.tectonic_aws_extra_tags}"
  enable_etcd_sg          = "${!var.tectonic_experimental && length(compact(var.tectonic_etcd_servers)) == 0 ? 1 : 0}"

  # VPC layout settings.
  #
  # The following parameters control the layout of the VPC accross availability zones.
  # Two modes are available:
  # A. Explicitly configure a list of AZs + associated subnet CIDRs
  # B. Let the module calculate subnets accross a set number of AZs
  #
  # To enable mode A, configure a set of AZs + CIDRs for masters and workers using the
  # "tectonic_aws_master_custom_subnets" and "tectonic_aws_worker_custom_subnets" variables.
  #
  # To enable mode B, make sure that "tectonic_aws_master_custom_subnets" and "tectonic_aws_worker_custom_subnets"
  # ARE NOT SET.

  # These counts could be deducted by length(keys(var.tectonic_aws_master_custom_subnets))
  # but there is a restriction on passing computed values as counts. This approach works around that.
  master_az_count = "${length(keys(var.tectonic_aws_master_custom_subnets)) > 0 ? "${length(keys(var.tectonic_aws_master_custom_subnets))}" : "${length(data.aws_availability_zones.azs.names)}"}"
  worker_az_count = "${length(keys(var.tectonic_aws_worker_custom_subnets)) > 0 ? "${length(keys(var.tectonic_aws_worker_custom_subnets))}" : "${length(data.aws_availability_zones.azs.names)}"}"
  # The appending of the "padding" element is required as workaround since the function
  # element() won't work on empty lists. See https://github.com/hashicorp/terraform/issues/11210
  master_subnets = "${concat(values(var.tectonic_aws_master_custom_subnets),list("padding"))}"
  worker_subnets = "${concat(values(var.tectonic_aws_worker_custom_subnets),list("padding"))}"
  # The split() / join() trick works around the limitation of ternary operator expressions
  # only being able to return strings.
  master_azs = "${ split("|", "${length(keys(var.tectonic_aws_master_custom_subnets))}" > 0 ?
    join("|", keys(var.tectonic_aws_master_custom_subnets)) :
    join("|", data.aws_availability_zones.azs.names)
  )}"
  worker_azs = "${ split("|", "${length(keys(var.tectonic_aws_worker_custom_subnets))}" > 0 ?
    join("|", keys(var.tectonic_aws_worker_custom_subnets)) :
    join("|", data.aws_availability_zones.azs.names)
  )}"
}

module "dns" {
  source = "../../modules/aws-gov/powerdns"
  base_domain        = "${var.tectonic_base_domain}"
  cl_channel         = "${var.tectonic_cl_channel}"
  cluster_id         = "test1"
  cluster_name       = "${var.tectonic_cluster_name}"
  container_image    = "${var.tectonic_container_images["etcd"]}"
#  dns_enabled        = "${!var.tectonic_experimental && length(compact(var.tectonic_etcd_servers)) ==     0}"
#  dns_zone_id        = "${var.tectonic_aws_private_endpoints ? data.null_data_source.zones.inputs["pri    vate"] : data.null_data_source.zones.inputs["public"]}"
  ec2_type           = "${var.tectonic_aws_worker_ec2_type}"
 # external_endpoints = "${compact(var.tectonic_etcd_servers)}"
  extra_tags         = "${var.tectonic_aws_extra_tags}"
  instance_count     = 1
  root_volume_iops   = "${var.tectonic_aws_worker_root_volume_iops}"
  root_volume_size   = "${var.tectonic_aws_worker_root_volume_size}"
  root_volume_type   = "${var.tectonic_aws_worker_root_volume_type}"
  sg_ids             = "${concat(var.tectonic_aws_worker_extra_sg_ids, list(module.vpc.worker_sg_id))}"
  ssh_key            = "${var.tectonic_aws_ssh_key}"
  subnets            = "${module.vpc.worker_subnet_ids}"
}


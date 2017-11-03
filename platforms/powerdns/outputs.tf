output "worker_subnet_id" {
  value = "${module.vpc.worker_subnet_ids}"
}

output "vpc_id" {
  value = "${module.vpc.vpc_id}"
}

output "etcd_sg_id" {
  value = "${module.vpc.etcd_sg_id}"
}

output "api_sg_id" {
  value = "${module.vpc.api_sg_id}"
}

output "console_sg_id" {
  value = "${module.vpc.console_sg_id}"
}

output "master_sg_id" {
  value = "${module.vpc.master_sg_id}"
}

output "master_subnet_ids" {
  value = "${module.vpc.master_subnet_ids}"
}

output "worker_sg_id" {
  value = "${module.vpc.worker_sg_id}"
}

output "worker_subnet_ids" {
  value = "${module.vpc.worker_subnet_ids}"
}

output "nameserver_ip" {
  value = "${module.dns.server_ip}"
}

output "nameserver_url" {
  value = "${module.dns.server_url}"
}


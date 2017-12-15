variable "ssh_key" {
  type = "string"
}

#variable "dns_zone_id" {
#  type = "string"
#}

variable "base_domain" {
  type = "string"
}

#variable "vpc_id" {
#  type = "string"
#}

variable "cl_channel" {
  type = "string"
}

variable "cluster_id" {
  type = "string"
}

variable "cluster_name" {
  type = "string"
}

variable "container_image" {
  type = "string"
}

variable "ec2_type" {
  type = "string"
}

variable "instance_count" {
  type = "string"
}

#variable "subnet_ids" {
#  type = "list"
#}

variable "subnets" {
  type = "list"
}


variable "sg_ids" {
  type        = "list"
  description = "The security group IDs to be applied."
}

variable "load_balancers" {
  description = "List of ELBs to attach all worker instances to."
  type        = "list"
  default     = []
}

variable "extra_tags" {
  description = "Extra AWS tags to be applied to created resources."
  type        = "map"
  default     = {}
}

variable "autoscaling_group_extra_tags" {
  description = "Extra AWS tags to be applied to created autoscaling group resources."
  type        = "list"
  default     = []
}

variable "root_volume_type" {
  type        = "string"
  description = "The type of volume for the root block device."
}

variable "root_volume_size" {
  type        = "string"
  description = "The size of the volume in gigabytes for the root block device."
}

variable "root_volume_iops" {
  type        = "string"
  default     = "100"
  description = "The amount of provisioned IOPS for the root block device."
}

variable "worker_iam_role" {
  type        = "string"
  default     = ""
  description = "IAM role to use for the instance profiles of worker nodes."
}

variable "external_dns" {
  description = "Enables public Elastic IPs for the PowerDNS server"
  type        = "string"
}

variable "aws_dns_server" {
  description = "AWS DNS server associated with your VPC CIDR. The AWS DNS Server will be the third (Network ID being the first) IP address in your VPC CIDR range. Ex: For CIDR 10.0.0.0/24 the AWS DNS Server will be 10.0.0.2"
  type        = "string"
}

data "aws_ami" "coreos_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["CoreOS-${var.cl_channel}-*"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "owner-id"
    values = ["190570271432"]
  }
}

resource "aws_db_subnet_group" "mysql" {
  name        = "mysql_subnet_group"
  description = "DB Subnet Group"
  subnet_ids  = ["${var.subnets}"]
}

resource "aws_db_instance" "mysql" {
  allocated_storage      = 50
  storage_type           = "gp2"
  engine                 = "mysql"
  engine_version         = "5.7.17"
  instance_class         = "db.t2.micro"
  name                   = "db_create"
  username               = "root"
  password               = "powerdns"
  db_subnet_group_name   = "mysql_subnet_group"
  vpc_security_group_ids = ["${var.sg_ids}"]
}

resource "aws_instance" "powerdns_node" {
  count = "1"
  ami   = "${data.aws_ami.coreos_ami.image_id}"

  instance_type          = "${var.ec2_type}"
  subnet_id              = "${element(var.subnets, count.index)}"
  key_name               = "${var.ssh_key}"
  user_data              = "${data.ignition_config.powerdns.rendered}"
  vpc_security_group_ids = ["${var.sg_ids}"]

  lifecycle {
    # Ignore changes in the AMI which force recreation of the resource. This
    # avoids accidental deletion of nodes whenever a new CoreOS Release comes
    # out.
    ignore_changes = ["ami"]
  }

  tags = "${merge(map(
      "Name", "${var.cluster_name}-powerdns-${count.index}",
      "kubernetes.io/cluster/${var.cluster_name}", "owned",
      "tectonicClusterID", "${var.cluster_id}"
    ), var.extra_tags)}"

  root_block_device {
    volume_type = "${var.root_volume_type}"
    volume_size = "${var.root_volume_size}"
    iops        = "${var.root_volume_type == "io1" ? var.root_volume_iops : var.root_volume_type == "gp2" ? min(10000, max(100, 3 * var.root_volume_size)) : 0}"
  }

  volume_tags = "${merge(map(
    "Name", "${var.cluster_name}-powerdns-${count.index}-vol",
    "kubernetes.io/cluster/${var.cluster_name}", "owned",
    "tectonicClusterID", "${var.cluster_id}"
  ), var.extra_tags)}"

}

resource "aws_elb" "api_internal" {
  count           = "${var.private_endpoints}"
  name            = "${var.cluster_name}-int"
  subnets         = ["${var.subnet_ids}"]
  internal        = true
  security_groups = ["${var.api_sg_ids}"]

  idle_timeout                = 3600
  connection_draining         = true
  connection_draining_timeout = 300

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "SSL:443"
    interval            = 5
  }

  tags = "${merge(map(
      "Name", "${var.cluster_name}-int",
      "kubernetes.io/cluster/${var.cluster_name}", "owned",
      "tectonicClusterID", "${var.cluster_id}"
    ), var.extra_tags)}"
}

resource "powerdns_record" "api_internal" {
  count   = "${var.private_endpoints}"
  zone    = "${var.base_domain}"
  name    = "${var.custom_dns_name == "" ? var.cluster_name : var.custom_dns_name}-api.${var.base_domain}."
  ttl     = 60
  type    = "ALIAS"

  records  = ["${aws_elb.api_internal.dns_name}."]
}

resource "aws_elb" "api_external" {
  count           = "${var.public_endpoints}"
  name            = "${var.custom_dns_name == "" ? var.cluster_name : var.custom_dns_name}-ext"
  subnets         = ["${var.subnet_ids}"]
  internal        = false
  security_groups = ["${var.api_sg_ids}"]

  idle_timeout                = 3600
  connection_draining         = true
  connection_draining_timeout = 300

  listener {
    instance_port     = 443
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "SSL:443"
    interval            = 5
  }

  tags = "${merge(map(
      "Name", "${var.cluster_name}-api-external",
      "kubernetes.io/cluster/${var.cluster_name}", "owned",
      "tectonicClusterID", "${var.cluster_id}"
    ), var.extra_tags)}"
}

resource "powerdns_record" "api_external" {
  count   = "${var.public_endpoints}"
  zone    = "${var.base_domain}"
  name    = "${var.custom_dns_name == "" ? var.cluster_name : var.custom_dns_name}-api.${var.base_domain}."
  type    = "ALIAS"
  ttl	  = 60
  records  = ["${aws_elb.api_external.dns_name}."]
}

resource "aws_elb" "console" {
  name            = "${var.custom_dns_name == "" ? var.cluster_name : var.custom_dns_name}-con"
  subnets         = ["${var.subnet_ids}"]
  internal        = "${var.public_endpoints ? false : true}"
  security_groups = ["${var.console_sg_ids}"]

  idle_timeout = 3600

  listener {
    instance_port     = 32001
    instance_protocol = "tcp"
    lb_port           = 80
    lb_protocol       = "tcp"
  }

  listener {
    instance_port     = 32000
    instance_protocol = "tcp"
    lb_port           = 443
    lb_protocol       = "tcp"
  }

  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    target              = "HTTP:32002/healthz"
    interval            = 5
  }

  tags = "${merge(map(
      "Name", "${var.cluster_name}-console",
      "kubernetes.io/cluster/${var.cluster_name}", "owned",
      "tectonicClusterID", "${var.cluster_id}"
    ), var.extra_tags)}"
}

resource "powerdns_record" "ingress_public" {
  count   = "${var.public_endpoints}"
  zone    = "${var.base_domain}"
  name    = "${var.custom_dns_name == "" ? var.cluster_name : var.custom_dns_name}.${var.base_domain}."
  type    = "ALIAS"
  ttl     = 60
  records  = ["${aws_elb.console.dns_name}."]
}

resource "powerdns_record" "ingress_private" {
  count   = "${var.private_endpoints}"
  zone    = "${var.base_domain}"
  name    = "${var.custom_dns_name == "" ? var.cluster_name : var.custom_dns_name}.${var.base_domain}."
  type    = "ALIAS"
  ttl     = 60
  records  = ["${aws_elb.console.dns_name}."]
}

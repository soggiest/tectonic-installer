data "ignition_config" "powerdns" {
  count = "1"

  systemd = [
    "${data.ignition_systemd_unit.powerdns.id}",
  ]

  files = [
    "${data.ignition_file.node_hostname.id}",
    "${data.ignition_file.createzone.id}",
  ]
}


data "ignition_file" "node_hostname" {
  path       = "/etc/hostname"
  mode       = 0644
  filesystem = "root"

  content {
    content = "${var.cluster_name}-powerdns.${var.base_domain}"
  }
}

data "ignition_file" "createzone" {
  path       = "/home/core/createzone"
  mode       = 0755
  filesystem = "root"

  content {
    content = <<EOF
#!/usr/bin/bash

sleep 30s
docker exec pdns-master pdnsutil create-zone $1
EOF
  }
}

data "ignition_systemd_unit" "powerdns" {
  name   = "powerdns.service"
  enable = true

  content = <<EOF
[Unit]
Description=Run the PowerDNS Service
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=true

User=root
Group=root

#ExecStartPre=/usr/bin/docker load --input /tmp/pdns-4.0-1.tar.gz
#ExecStartPre=/usr/bin/docker load --input /tmp/mysql.tar.gz
ExecStartPre=/usr/bin/docker pull quay.io/nicholas_lane/pdns:4.0-1
ExecStartPre=/usr/bin/docker pull mysql
ExecStartPre=/usr/bin/docker run -d --name=mysql -e MYSQL_ROOT_PASSWORD=changeme mysql
ExecStart=/usr/bin/docker run --name pdns-master --link mysql:db -p 53:53/udp -p 53:53 -p 8081:8081 -d -e PDNS_RECURSOR=10.0.0.2 -e PDNS_SOA=10.0.0.2 -e PDNS_ALLOW_AXFR_IPS=127.0.0.1 -e PDNS_DISTRIBUTOR_THREADS=3 -e PDNS_CACHE_TTL=20 -e PDNS_RECURSIVE_CACHE_TTL=10 -e DB_ENV_MYSQL_ROOT_PASSWORD=changeme -e PDNS_ZONE="${var.base_domain}" quay.io/nicholas_lane/pdns:4.0-1
ExecStartPost=-/home/core/createzone "${var.base_domain}"

ExecStopPost=/usr/bin/docker kill mysql
ExecStopPost=/usr/bin/docker rm mysql
ExecStopPost=/usr/bin/docker kill pdns-master
ExecStopPost=/usr/bin/docker rm pdns-master

[Install]
WantedBy=multi-user.target

EOF
}

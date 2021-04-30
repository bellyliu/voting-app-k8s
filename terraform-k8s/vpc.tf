resource "alicloud_vpc" "vpc" {
  vpc_name   = "demo-niagahosting"
  cidr_block = "192.168.0.0/16"
}

resource "alicloud_vswitch" "vswitch" {
  vpc_id            = alicloud_vpc.vpc.id
  cidr_block        = "192.168.1.0/24"
  zone_id           = var.zone
}

resource "alicloud_security_group" "sec_group" {
  name      = "demo-sg"
  vpc_id    = alicloud_vpc.vpc.id
}

resource "alicloud_security_group_rule" "allow_all_tcp" {
  type              = "ingress"
  ip_protocol       = "tcp"
  nic_type          = "intranet"
  policy            = "accept"
  port_range        = "1/65535"
  priority          = 1
  security_group_id = alicloud_security_group.sec_group.id
  cidr_ip           = "0.0.0.0/0"
}
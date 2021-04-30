resource "alicloud_cs_managed_kubernetes" "k8s" {
  version               = "1.16.9-aliyun.1"
  name                  = "demo-niagahosting"
  security_group_id     = alicloud_security_group.sec_group.id
  cluster_spec          = "ack.standard"
  load_balancer_spec    = "slb.s1.small"
  service_cidr          = "172.21.0.0/20"
  pod_cidr              = "172.20.0.0/16"
  new_nat_gateway       = true
  enable_ssh            = true
  proxy_mode            = "iptables"
  key_name              = "mypair"
  worker_vswitch_ids    = alicloud_vswitch.vswitch.*.id
  worker_instance_types = ["ecs.g5.large"]
  worker_number         = 2
  worker_disk_category  = "cloud_efficiency"
  worker_disk_size      = "40"
}
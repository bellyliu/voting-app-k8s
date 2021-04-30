resource "alicloud_ess_scaling_group" "worker-asg" {
  min_size           = 1
  max_size           = 5
  scaling_group_name = "k8s-worker-asg"
  default_cooldown   = 60
  vswitch_ids        = alicloud_vswitch.vswitch.*.id
  removal_policies   = ["OldestInstance", "NewestInstance"]
}

resource "alicloud_ess_scaling_configuration" "worker-asc" {
  scaling_configuration_name  = "worker-asc"
  scaling_group_id            = alicloud_ess_scaling_group.worker-asg.id
  image_id                    = "centos_7_9_x64_20G_alibase_20210318.vhd"
  instance_type               = "ecs.g5.large"
  security_group_id           = alicloud_security_group.sec_group.id
  internet_charge_type        = "PayByTraffic"
  key_name                    = "mypair"
  instance_name               = "worker-k8s"
  force_delete                = true
  enable                      = true
  active                      = true
}
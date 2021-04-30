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
  key_name              = "mypair"
  worker_vswitch_ids    = alicloud_vswitch.vswitch.*.id
  worker_instance_types = ["ecs.g5.large"]
  worker_number         = 2

  runtime = {
    name = "docker"
    version = "19.03.5"
  }

  dynamic "addons" {
      for_each = var.cluster_addons
      content {
        name          = lookup(addons.value, "name", var.cluster_addons)
        config        = lookup(addons.value, "config", var.cluster_addons)
        disabled      = lookup(addons.value, "disabled", var.cluster_addons)
      }
  }
}

resource "alicloud_cs_kubernetes_autoscaler" "default" {
  cluster_id              = alicloud_cs_managed_kubernetes.k8s.id
  nodepools {
    id                    = alicloud_ess_scaling_group.worker-asg.id
    labels                = "name=k8sWorker"
  }

  utilization             = 80
  cool_down_duration      = 60
  defer_scale_in_duration = 60

  depends_on = [alicloud_ess_scaling_group.worker-asg, alicloud_ess_scaling_configuration.worker-asc]
}

# resource "alicloud_cs_kubernetes_node_pool" "auto-np" {
#   name                         = "worker-node-pool"
#   cluster_id                   = alicloud_cs_managed_kubernetes.k8s.id
#   vswitch_ids                  = alicloud_vswitch.vswitch.*.id
#   instance_types               = ["ecs.g5.large"]
#   system_disk_category         = "cloud_efficiency"
#   system_disk_size             = 40
#   key_name                     = "mypair"
  
#   # automatic scaling node pool configuration.
#   scaling_config {
#     min_size      = 1
#     max_size      = 3
#   }
# }
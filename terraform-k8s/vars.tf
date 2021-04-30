variable access_key {
  description = "desc"
}
variable secret_key {
  description = "desc"
}
variable region {
  default     = "ap-southeast-5"
}
variable zone {
  default     = "ap-southeast-5a"
}
variable "cluster_addons" {
  description = "Addon components in kubernetes cluster"

  type = list(object({
    name      = string
    config    = string
    disabled  = bool
  }))

  default = [
    {
      "name"     = "flannel",
      "config"   = "",
      "disabled" = false
    },
    {
      "name"     = "flexvolume",
      "config"   = "",
      "disabled" = false
    }
  ]
}


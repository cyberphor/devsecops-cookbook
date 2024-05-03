variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type    = string
  default = "squidfall"
}

variable "container_registry_name" {
  type    = string
  default = "squidfall"
}

variable "kubernetes_cluster_name" {
  type    = string
  default = "squidfall"
}

variable "kubernetes_node_size" {
  type    = string
  default = "Standard_DS2_v2" 
}

variable "kubernetes_node_count" {
  type    = number
  default = 4 
}
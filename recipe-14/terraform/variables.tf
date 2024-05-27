variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type = string
  sensitive = true
}

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_node_name" {
  type = string
  default = "hypervisor-01"
}

variable "vm_template_name" {
  type = string
  default = "k8s-node"
}

variable "vm_name" {
  type = string
  default = "k8s-controller"
}
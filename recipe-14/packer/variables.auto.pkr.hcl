variable "proxmox_node_name" {
  type = string
  default = "hypervisor-01"
}

variable "proxmox_api_url" {
  type = string
}

variable "proxmox_api_token_id" {
  type = string
}

variable "proxmox_api_token_secret" {
  type = string
  sensitive = true
}

variable "iso_file" {
  type = string
  default = "local:iso/ubuntu-22.04.4-live-server-amd64.iso"
}

variable "vm_id" {
  type = string
  default = "100"
}

variable "vm_name" {
  type = string
  default = "k8s-node"
}

variable "vm_template_description" {
  type = string
  default = "Ubuntu Server w/Kubernetes pre-installed"
}

variable "vm_cores" {
  type = string
  default = "2"
}

variable "vm_memory" {
  type = string
  default = "4096"
}

variable "vm_disk_size" {
  type = string
  default = "20G"
}

variable "vm_admin_username" {
  type = string
  default = "packer"
}

variable "vm_admin_password" {
  type = string
  default = "packer"
}

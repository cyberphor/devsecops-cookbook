# this file is for organizing variables. if you need to assign sensitive values, 
# declare the variable here first then set the value in a secret.pkrvars.hcl file.
# Packer will automatically load this file (because it ends with .pkr.hcl), but 
# you'll have to manually specify secret.pkrvars.hcl (if you create one) when you 
# invoke "packer validate" or "packer build"

variable "tenant_id" {
  type      = string
  default   = null
}

variable "subscription_id" {
  type    = string
  default = null
}

variable "client_id" {
  type    = string
  default = null
}

variable "client_secret" {
  type    = string
  default = null
}

variable "location" {
  type    = string
  default = "eastus2"
}

variable "resource_group_name" {
  type    = string
  default = null # this must exist already; this is where the image is stored
}

variable "managed_image_resource_group" {
  type    = string
  default = "template-rg"
}

variable "managed_image_name" {
  type    = string
  default = "template-vm" # this is what the image will be called in your "resource_group"
}

variable "vm_os_type" {
  type    = string
  default = "Linux" 
}

variable "vm_image_publisher" {
  type    = string
  default = "Canonical" 
}

variable "vm_image_offer" {
  type    = string
  default = "0001-com-ubuntu-server-jammy" 
}

variable "vm_image_sku" {
  type    = string
  default = "22_04-lts" 
}

variable "vm_size" {
  type    = string
  default = "Standard_B2s"
}
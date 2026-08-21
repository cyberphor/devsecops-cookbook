variable "location" {
  type    = string
  default = "eastus"
}

variable "resource_group_name" {
  type    = string
  default = "windows"
}

variable "vm_size" {
  type    = string
  default = "Standard_DS1_v2"
}

variable "vm_image_publisher" {
  type    = string
  default = "MicrosoftWindowsServer"
}

variable "vm_image_offer" {
  type    = string
  default = "WindowsServer" 
}

variable "vm_image_sku" {
  type    = string
  default = "2022-Datacenter"
}

variable "vm_image_version" {
  type    = string
  default = "latest" 
}

variable "computer_name" {
  type    = string
  default = "XYZ9000DC01"
}

variable "local_admin_username" {
  type    = string
  default = "victor"
}

variable "local_admin_password" {
  type    = string
  default = "Password123!"
}
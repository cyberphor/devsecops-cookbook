variable "location" {
  type = string
  default = "eastus"
}

variable "image_version" {
  type    = string
  default = "v1.0.0"
}

variable "container_port" {
  type    = number
  default = 1337
}

variable "volume_mount_path" {
  type    = string
  default = "/opt/minecraft-server/world"
}
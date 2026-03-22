variable "region" {
    type = string
}

variable "resource_group" {
    type = string
}

variable "name" {
    type = string
}

variable "sku" {
    type = string
}

variable "retention_in_days" {
    type = number
}

variable "grafana_managed_identity" {
    type = string
}
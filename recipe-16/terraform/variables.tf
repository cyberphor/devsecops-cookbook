variable "tenant_id" {
    type    = string
}

variable "subscription_id" {
    type    = string
}

variable "region" {
    type    = string
    default = "eastus"
}

variable "csp" {
    type    = string
    default = "az"
}

variable "app" {
    type    = string
    default = "squidfall"
}

variable "env" {
    type    = string
    default = "d"
}

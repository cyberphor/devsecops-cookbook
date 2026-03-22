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
    default = "cannon"
}

variable "env" {
    type    = string
    default = "d"
}

variable "sku" {
    type        = string
    description = "https://docs.microsoft.com/en-us/azure/analysis-services/analysis-services-overview#availability-by-region"
    default     = "S0"
}
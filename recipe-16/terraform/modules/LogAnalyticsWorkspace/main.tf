resource "azurerm_log_analytics_workspace" "main" {
    location            = var.region
    resource_group_name = var.resource_group
    name                = var.name
    sku                 = var.sku
    retention_in_days   = var.retention_in_days
}
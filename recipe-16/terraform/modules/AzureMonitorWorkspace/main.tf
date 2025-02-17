resource "azurerm_monitor_workspace" "main" {
    location            = var.region
    resource_group_name = var.resource_group
    name                = var.name
}

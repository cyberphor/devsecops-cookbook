resource "azurerm_container_registry" "main" {
  location            = var.region
  resource_group_name = var.resource_group
  name                = var.name
  sku                 = var.sku
  admin_enabled       = true
}

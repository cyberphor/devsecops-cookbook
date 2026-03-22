resource "azurerm_cognitive_account" "main" {
    location            = var.region
    resource_group_name = var.resource_group
    name                = var.name
    sku_name            = var.sku
    local_auth_enabled  = true
    kind                = "OpenAI"
}

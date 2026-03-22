resource "azurerm_log_analytics_workspace" "main" {
    location            = var.region
    resource_group_name = var.resource_group
    name                = var.name
    sku                 = var.sku
    retention_in_days   = var.retention_in_days
}

resource "azurerm_role_assignment" "grafana" {
    principal_id                     = var.grafana_managed_identity
    role_definition_name             = "Log Analytics Reader"
    scope                            = azurerm_log_analytics_workspace.main.id
    skip_service_principal_aad_check = true
    principal_type                   = "ServicePrincipal"
}

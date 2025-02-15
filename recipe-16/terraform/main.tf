resource "azurerm_resource_group" "main" {
    name     = upper("${var.csp}-${var.app}-${var.env}")
    location = var.region
}

module "names" {
    csp    = var.csp
    app    = var.app
    env    = var.env
    source = "./modules/Names"
}

module "LogAnalyticsWorkspace" {
    resource_group    = azurerm_resource_group.main.name
    region            = azurerm_resource_group.main.location
    name              = module.names.resources["law"]
    sku               = "PerGB2018"
    retention_in_days = 730
    source            = "./modules/LogAnalyticsWorkspace"
}

module "AzureContainerRegistry" {
    resource_group    = azurerm_resource_group.main.name
    region            = azurerm_resource_group.main.location
    name              = module.names.resources["acr"]
    sku               = "Basic"
    source            = "./modules/AzureContainerRegistry"
}

module "AzureKubernetesService" {
    resource_group    = azurerm_resource_group.main.name
    region            = azurerm_resource_group.main.location
    name              = module.names.resources["aks"]
    node_size         = "Standard_DS2_v2"
    node_count        = 4
    acr_id            = module.AzureContainerRegistry.id
    source            = "./modules/AzureKubernetesService"
}

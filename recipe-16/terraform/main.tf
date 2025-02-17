terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = ">=3.110.0"
        }
        grafana = {
            source = "grafana/grafana"
            version = "3.19.0"
        }
    }
}

provider "azurerm" {
    subscription_id = var.subscription_id
    features {
        resource_group {
            prevent_deletion_if_contains_resources = false
        }
    }
}

// TODO: replace the "auth" value with a Service Principal.
provider "grafana" {
    url  = module.AzureManagedGrafana.endpoint              
    auth = "" 
}

data "azurerm_subscription" "main" {}

data "azuread_client_config" "main" {}

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
    resource_group           = azurerm_resource_group.main.name
    region                   = azurerm_resource_group.main.location
    name                     = module.names.resources["law"]
    sku                      = "PerGB2018"
    retention_in_days        = 730
    grafana_managed_identity = "f3809164-ec07-41a6-a1f6-8a4a1c867505" // TODO: replace with a Service Principal.
    source                   = "./modules/LogAnalyticsWorkspace"
}

module "AzureMonitorWorkspace" {
    resource_group    = azurerm_resource_group.main.name
    region            = azurerm_resource_group.main.location
    name              = module.names.resources["amw"]
    source            = "./modules/AzureMonitorWorkspace"
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
    law_id            = module.LogAnalyticsWorkspace.id
    source            = "./modules/AzureKubernetesService"
}

module "AzureManagedGrafana" {
    resource_group    = azurerm_resource_group.main.name
    region            = azurerm_resource_group.main.location
    name              = module.names.resources["amg"]
    amw_id            = module.AzureMonitorWorkspace.id
    app               = var.app
    current_user_id   = data.azuread_client_config.main.object_id
    subscription_id   = data.azurerm_subscription.main.id
    source            = "./modules/AzureManagedGrafana"
}

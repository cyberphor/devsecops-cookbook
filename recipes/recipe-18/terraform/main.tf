terraform {
    required_providers {
        azurerm = {
            source  = "hashicorp/azurerm"
            version = ">=3.110.0"
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

data "azurerm_subscription" "main" {}

resource "azurerm_resource_group" "main" {
    name     = upper("${var.csp}-${var.app}-${var.env}")
    location = var.region
}

module "AzureOpenAI" {
    resource_group = azurerm_resource_group.main.name
    region         = azurerm_resource_group.main.location
    name           = upper("${var.csp}-${var.app}-${var.env}-aoai")
    sku            = var.sku
    source         = "./modules/AzureOpenAI"
}

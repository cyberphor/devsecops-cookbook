resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_container_registry" "main" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = var.container_registry_name
  sku                 = "Basic" 
  admin_enabled       = true
}

resource "azurerm_kubernetes_cluster" "main" {
  name                = var.kubernetes_cluster_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  node_resource_group = "${azurerm_resource_group.main.name}-kubernetes-nodes"
  dns_prefix          = azurerm_resource_group.main.name
  default_node_pool {
    name       = "default"
    node_count = var.kubernetes_node_count
    vm_size    = var.kubernetes_node_size
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "main" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.main.id
  skip_service_principal_aad_check = true
}
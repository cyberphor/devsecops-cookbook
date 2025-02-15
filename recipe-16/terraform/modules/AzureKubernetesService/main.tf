
resource "azurerm_kubernetes_cluster" "main" {
  location            = var.region
  resource_group_name = var.resource_group
  name                = var.name
  node_resource_group = "${var.name}-nodes"
  dns_prefix          = var.resource_group
  default_node_pool {
    name       = "default"
    node_count = var.node_count
    vm_size    = var.node_size
  }
  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_role_assignment" "main" {
  principal_id                     = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name             = "AcrPull"
  scope                            = var.acr_id
  skip_service_principal_aad_check = true
}
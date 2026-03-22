output "ACR_NAME" {
  value = azurerm_container_registry.main.name 
}

output "AKS_NAME" {
  value = azurerm_kubernetes_cluster.main.name
}
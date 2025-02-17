output "endpoint" {
    value = azurerm_cognitive_account.main.endpoint
}

output "primary_access_key" {
    value = azurerm_cognitive_account.main.primary_access_key
    sensitive = true
}

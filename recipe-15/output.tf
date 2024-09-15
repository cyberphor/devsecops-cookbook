output "ip-addresses" {
  value = values(azurerm_public_ip.main)[*].ip_address
}
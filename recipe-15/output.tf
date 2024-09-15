output "ip-addresses" {
  value = sort(values(azurerm_public_ip.main)[*].ip_address)
}
output "next_step" {
  value = "ssh ${var.local_admin_username}@${azurerm_public_ip.main.ip_address}"
}
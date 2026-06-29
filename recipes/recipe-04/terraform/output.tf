output "username" {
  value = var.local_admin_username
}

output "ip_address" {
  value = azurerm_public_ip.main.ip_address
}

resource "local_file" "main" {
  content  = yamlencode({
    "all": {
      "hosts": {
        "${azurerm_public_ip.main.ip_address}": ""
      }
    }
  })
  filename = "${path.module}/../ansible/inventory.yaml"
}


output "ip-addresses" {
  value = values(azurerm_public_ip.main)[*].ip_address
}

resource "local_file" "main" {
  content  = yamlencode({
    "all": {
      "hosts": { for nic in azurerm_public_ip.main : nic.ip_address => "" }
    }
  })
  filename = "${path.module}/../ansible/inventory.yaml"
}
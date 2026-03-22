output "connect" {
  value = "${azurerm_container_group.main.fqdn}:${var.container_port}"
}

output "start" {
  value = "https://${azurerm_linux_function_app.main.default_hostname}/api/start"
}

output "stop" {
  value = "https://${azurerm_linux_function_app.main.default_hostname}/api/stop"
}

#output "host_key" {
#  value = data.azurerm_function_app_host_keys.main.default_function_key
#  sensitive = true
#}

source "azure-arm" "main" {
  subscription_id                   = var.subscription_id
  tenant_id                         = var.tenant_id
  client_id                         = var.client_id
  client_secret                     = var.client_secret
  location                          = var.location
  managed_image_resource_group_name = var.resource_group
  managed_image_name                = var.managed_image_name
  vm_size                           = var.vm_size
  os_type                           = var.vm_os_type
  image_publisher                   = var.image_publisher
  image_offer                       = var.vm_image_offer
  image_sku                         = var.vm_image_sku
}

build {
  sources = [
    "source.azure-arm.example"
  ]

  provisioner "shell" {
    inline_shebang  = "/bin/sh -x"
    execute_command = "chmod +x {{ .Path }}; {{ .Vars }} sudo -E sh '{{ .Path }}'"
    script = "../scripts/setup.sh"
  }
}

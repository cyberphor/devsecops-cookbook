resource "random_pet" "value" {
  length    = 2
  separator = ""
}

resource "azurerm_resource_group" "main" {
  name     = random_pet.value.id
  location = var.location
}

resource "azurerm_storage_account" "main" {
  name                     = random_pet.value.id
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_share" "main" {
  name                 = random_pet.value.id
  storage_account_name = azurerm_storage_account.main.name
  quota                = 1 # GB
}

resource "azurerm_container_registry" "main" {
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  name                = random_pet.value.id
  sku                 = "Basic" 
  admin_enabled       = true
}

resource "azuread_application" "main" {
  display_name = random_pet.value.id
}

resource "azuread_service_principal" "main" {
  application_id = azuread_application.main.application_id
}

resource "azuread_service_principal_password" "main" {
  service_principal_id = azuread_service_principal.main.object_id
}

resource "azurerm_role_assignment" "main" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPush"
  principal_id         = azuread_service_principal.main.object_id
  principal_type       = "ServicePrincipal"
}

resource "terraform_data" "docker" {
  triggers_replace = [ var.image_version ]
  depends_on = [ azurerm_role_assignment.main ]
  provisioner "local-exec" {
    command = "docker image build --rm --tag ${random_pet.value.id}:${var.image_version} ../docker"
  }
  provisioner "local-exec" {
    command = "docker tag ${random_pet.value.id}:${var.image_version} ${azurerm_container_registry.main.name}.azurecr.io/${random_pet.value.id}:${var.image_version}"
  }
  provisioner "local-exec" {
    command = "az acr login -n ${azurerm_container_registry.main.name} -u ${azuread_service_principal.main.application_id} -p ${azuread_service_principal_password.main.value}"
  }
  provisioner "local-exec" {
    command = "docker push ${azurerm_container_registry.main.name}.azurecr.io/${random_pet.value.id}:${var.image_version}"
  }
}

resource "azurerm_container_group" "main" {
  depends_on = [ terraform_data.docker ]
  name                = random_pet.value.id
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = "Standard"
  container {
    name   = random_pet.value.id
    image  = "${azurerm_container_registry.main.name}.azurecr.io/${random_pet.value.id}:${var.image_version}"
    cpu    = "2"
    memory = "2"
    ports {
      port     = var.container_port
      protocol = "TCP"
    }
    volume {
      name                 = azurerm_storage_share.main.name
      mount_path           = var.volume_mount_path
      read_only            = false
      storage_account_name = azurerm_storage_account.main.name
      storage_account_key  = azurerm_storage_account.main.primary_access_key
      share_name           = azurerm_storage_share.main.name
    }
  }
  image_registry_credential {
    server = "${azurerm_container_registry.main.name}.azurecr.io"
    username = azuread_service_principal.main.application_id
    password = azuread_service_principal_password.main.value
  }
  os_type             = "Linux"
  dns_name_label      = random_pet.value.id
  ip_address_type     = "Public"
}
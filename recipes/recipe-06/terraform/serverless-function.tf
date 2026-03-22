data "azurerm_client_config" "main" {}

resource "azurerm_service_plan" "main" {
  name                = random_pet.value.id
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  sku_name            = "S1" # Y1 = Consumption Plan
}

data "archive_file" "main" {
  type        = "zip"
  source_dir  = "${path.root}/../azure-functions"
  output_path = "${path.root}/function.zip"
}

resource "azurerm_linux_function_app" "main" {
  depends_on = [ data.archive_file.main ]
  name                        = random_pet.value.id
  resource_group_name         = azurerm_resource_group.main.name
  location                    = var.location
  service_plan_id             = azurerm_service_plan.main.id
  storage_account_name        = azurerm_storage_account.main.name
  storage_account_access_key  = azurerm_storage_account.main.primary_access_key
  https_only                  = true
  functions_extension_version = "~4"
  app_settings = {
    #"ENABLE_ORYX_BUILD"              = "true"                # enable on-the-fly builds
    #"SCM_DO_BUILD_DURING_DEPLOYMENT" = "true"                # enable on-the-fly builds
    "FUNCTIONS_WORKER_RUNTIME"       = "python"
    "AzureWebJobsFeatureFlags"       = "EnableWorkerIndexing"
    "SUBSCRIPTION_ID"                = data.azurerm_client_config.main.subscription_id,
    "RESOURCE_GROUP_NAME"            = azurerm_resource_group.main.name,
    "CONTAINER_GROUP_NAME"           = azurerm_container_group.main.name
  }
  site_config {
    always_on = true
  }
  zip_deploy_file = data.archive_file.main.output_path
}

#data "azurerm_function_app_host_keys" "main" {
#  name                = azurerm_linux_function_app.main.name
#  resource_group_name = azurerm_resource_group.main.name
#}
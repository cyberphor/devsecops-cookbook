terraform {
    required_providers {
        grafana = {
            source = "grafana/grafana"
            version = "3.19.0"
        }
    }
}

// TODO: add an App Registration resource.

// TODO: add a Service Principal resource.

resource "azurerm_dashboard_grafana" "main" {
    location                             = var.region
    resource_group_name                  = var.resource_group
    name                                 = var.name
    grafana_major_version                = 10
    api_key_enabled                      = true
    deterministic_outbound_ip_enabled    = true
    public_network_access_enabled        = true
    azure_monitor_workspace_integrations {
        resource_id = var.amw_id
    }
    identity {
        type = "SystemAssigned" // TODO: replace with the Service Principal resource mentioned above.
    }
}

// The AMG service must be able to enumerate resources (data sources) in the subscription to perform queries. 
resource "azurerm_role_assignment" "subscription_reader_grafana" {
    principal_id                     = azurerm_dashboard_grafana.main.identity[0].principal_id
    role_definition_name             = "Reader"
    scope                            = var.subscription_id
    skip_service_principal_aad_check = true
    principal_type                   = "ServicePrincipal"
}

// For US Government cloud, use "govazuremonitor" as the "cloudName" value.
resource "grafana_data_source" "azure-monitor" {
    type = "grafana-azure-monitor-datasource"
    name = "Azure Monitor Data Source"
    json_data_encoded = jsonencode({
        cloudName      = "azuremonitor"
        azureAuthType  = "msi"
        subscriptionId = var.subscription_id
    })
}

resource "grafana_folder" "platform" {
    title = "Platform"
}

locals {
    dashboard_panels_performance = [
        templatefile("${path.module}/dashboards/platform/performance/panel-01/panel.tmpl", {
            query = replace(
                file("${path.module}/dashboards/platform/performance/panel-01/query.kql"), "\n", ""
            )
        }),

        templatefile("${path.module}/dashboards/platform/performance/panel-02/panel.tmpl", {
            query = replace(
                file("${path.module}/dashboards/platform/performance/panel-02/query.kql"), "\n", ""
            )
        }),
    ]

    dashboard_panels_security = [
        templatefile("${path.module}/dashboards/platform/security/panel-01/panel.tmpl", {
            query = replace(
                file("${path.module}/dashboards/platform/security/panel-01/query.kql"), "\n", ""
            )
        }),

        templatefile("${path.module}/dashboards/platform/security/panel-02/panel.tmpl", {
            query = replace(
                file("${path.module}/dashboards/platform/security/panel-02/query.kql"), "\n", ""
            )
        }),
    ]
}

resource "grafana_dashboard" "performance" {
    folder = grafana_folder.platform.uid
    config_json = templatefile("${path.module}/dashboards/platform/dashboard.tmpl", {
        title = "Performance"
        uid   = "${var.app}-performance-dashboard"
        panels = join(",", local.dashboard_panels_performance)
    })
}

resource "grafana_dashboard" "security" {
    folder = grafana_folder.platform.uid
    config_json = templatefile("${path.module}/dashboards/platform/dashboard.tmpl", {
        title = "Security"
        uid   = "${var.app}-security-dashboard"
        panels = join(",", local.dashboard_panels_security)
    })
}

// The current user must be able to access the AMG service for development purposes.
resource "azurerm_role_assignment" "current_user" {
    principal_id                     = var.current_user_id
    role_definition_name             = "Grafana Admin"
    scope                            = azurerm_dashboard_grafana.main.id
    skip_service_principal_aad_check = true
    principal_type                   = "User"
}

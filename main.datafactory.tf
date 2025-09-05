resource "azurerm_data_factory" "this" {
  location                         = var.location
  name                             = var.name
  resource_group_name              = var.resource_group_name
  customer_managed_key_id          = var.customer_managed_key_id
  customer_managed_key_identity_id = var.customer_managed_key_identity_id
  managed_virtual_network_enabled  = var.managed_virtual_network_enabled
  public_network_enabled           = var.public_network_enabled
  purview_id                       = var.purview_id
  tags                             = var.tags

  dynamic "github_configuration" {
    for_each = var.github_configuration != null ? [var.github_configuration] : []

    content {
      account_name       = github_configuration.value.account_name
      branch_name        = github_configuration.value.branch_name
      repository_name    = github_configuration.value.repository_name
      root_folder        = github_configuration.value.root_folder
      git_url            = github_configuration.value.git_url
      publishing_enabled = github_configuration.value.publishing_enabled
    }
  }
  dynamic "global_parameter" {
    for_each = var.global_parameters

    content {
      name  = global_parameter.value.name
      type  = global_parameter.value.type
      value = global_parameter.value.value
    }
  }
  dynamic "identity" {
    for_each = local.managed_identities.system_assigned_user_assigned

    content {
      type         = identity.value.type
      identity_ids = identity.value.user_assigned_resource_ids
    }
  }
  dynamic "vsts_configuration" {
    for_each = var.vsts_configuration != null ? [var.vsts_configuration] : []

    content {
      account_name       = vsts_configuration.value.account_name
      branch_name        = vsts_configuration.value.branch_name
      project_name       = vsts_configuration.value.project_name
      repository_name    = vsts_configuration.value.repository_name
      root_folder        = vsts_configuration.value.root_folder
      tenant_id          = vsts_configuration.value.tenant_id
      publishing_enabled = vsts_configuration.value.publishing_enabled
    }
  }
}

resource "azurerm_management_lock" "this" {
  count = var.lock != null ? 1 : 0

  lock_level = var.lock.kind
  name       = coalesce(var.lock.name, "lock-${var.lock.kind}")
  scope      = azurerm_data_factory.this.id
  notes      = var.lock.kind == "CanNotDelete" ? "Cannot delete the resource or its child resources." : "Cannot delete or modify the resource or its child resources."

  depends_on = [
    azurerm_data_factory.this
  ]
}

resource "azurerm_data_factory_credential_service_principal" "this" {
  for_each = var.credential_service_principal

  data_factory_id      = azurerm_data_factory.this.id
  name                 = each.value.name
  service_principal_id = each.value.service_principal_id
  tenant_id            = each.value.tenant_id
  annotations          = each.value.annotations
  description          = each.value.description

  dynamic "service_principal_key" {
    for_each = each.value.service_principal_key != null ? [each.value.service_principal_key] : []

    content {
      linked_service_name = service_principal_key.value.linked_service_name
      secret_name         = service_principal_key.value.secret_name
      secret_version      = service_principal_key.value.secret_version
    }
  }
}

resource "azurerm_data_factory_credential_user_managed_identity" "this" {
  for_each = var.credential_user_managed_identity

  data_factory_id = azurerm_data_factory.this.id
  identity_id     = each.value.identity_id
  name            = each.value.name
  annotations     = each.value.annotations
  description     = each.value.description
}

resource "azurerm_monitor_diagnostic_setting" "this" {
  for_each = var.diagnostic_settings

  name                           = each.value.name != null ? each.value.name : "diag-${var.name}"
  target_resource_id             = azurerm_data_factory.this.id
  eventhub_authorization_rule_id = each.value.event_hub_authorization_rule_resource_id
  eventhub_name                  = each.value.event_hub_name
  log_analytics_destination_type = each.value.log_analytics_destination_type
  log_analytics_workspace_id     = each.value.workspace_resource_id
  partner_solution_id            = each.value.marketplace_partner_resource_id
  storage_account_id             = each.value.storage_account_resource_id

  dynamic "enabled_log" {
    for_each = each.value.log_categories

    content {
      category = enabled_log.value
    }
  }
  dynamic "enabled_log" {
    for_each = each.value.log_groups

    content {
      category_group = enabled_log.value
    }
  }
  dynamic "metric" {
    for_each = each.value.metric_categories

    content {
      category = metric.value
    }
  }
}

resource "azapi_resource" "cosmosdb_mongoapi_dataset" {
  for_each = var.dataset_cosmosdb_mongoapi

  name      = each.value.name
  parent_id = azurerm_data_factory.this.id
  type      = "Microsoft.DataFactory/factories/datasets@2018-06-01"
  body = {
    properties = {
      type = "CosmosDbMongoDbApiCollection"
      typeProperties = {
        collection = each.value.collection_name
      }
      linkedServiceName = {
        type          = "LinkedServiceReference"
        referenceName = each.value.linked_service_name
      }
      annotations = each.value.annotations
      description = each.value.description
      folder = each.value.folder != null ? {
        name = each.value.folder
      } : null
      parameters = each.value.parameters != null ? {
        for k, v in each.value.parameters : k => {
          type         = "String"
          defaultValue = v
        }
      } : null
    }
  }
  create_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers   = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  update_headers = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}

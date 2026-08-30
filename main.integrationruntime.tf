moved {
  from = azurerm_data_factory_integration_runtime_self_hosted.this
  to   = azapi_resource.integration_runtime_self_hosted
}

# AzAPI equivalent of the azurerm_data_factory_integration_runtime_self_hosted resource
resource "azapi_resource" "integration_runtime_self_hosted" {
  for_each = var.integration_runtime_self_hosted

  name      = each.value.name
  parent_id = azurerm_data_factory.this.id
  type      = var.resource_types.data_factory_integration_runtimes
  body = {
    properties = {
      type        = "SelfHosted"
      description = each.value.description
      typeProperties = {
        selfContainedInteractiveAuthoringEnabled = each.value.self_contained_interactive_authoring_enabled
        linkedInfo = each.value.rbac_authorization != null ? {
          authorizationType = "RBAC"
          resourceId        = each.value.rbac_authorization.resource_id
          credential = each.value.rbac_authorization.credential_name == null ? null : {
            type          = "CredentialReference"
            referenceName = each.value.rbac_authorization.credential_name
          }
        } : null
      }
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  replace_triggers_refs  = []
  response_export_values = ["*"]
  retry                  = var.retry
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null

  dynamic "timeouts" {
    for_each = var.timeouts == null ? [] : [var.timeouts]

    content {
      create = timeouts.value.create
      delete = timeouts.value.delete
      read   = timeouts.value.read
      update = timeouts.value.update
    }
  }

  depends_on = [
    azurerm_data_factory_credential_user_managed_identity.this,
  ]
}

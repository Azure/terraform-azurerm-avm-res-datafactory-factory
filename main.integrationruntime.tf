moved {
  from = azurerm_data_factory_integration_runtime_self_hosted.this
  to   = azapi_resource.integration_runtime_self_hosted
}

# AzAPI equivalent of the azurerm_data_factory_integration_runtime_self_hosted resource
resource "azapi_resource" "integration_runtime_self_hosted" {
  for_each = var.integration_runtime_self_hosted

  name      = each.value.name
  parent_id = azurerm_data_factory.this.id
  type      = "Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01"
  body = {
    properties = {
      type        = "SelfHosted"
      description = each.value.description
      typeProperties = {
        selfContainedInteractiveAuthoringEnabled = each.value.self_contained_interactive_authoring_enabled
        linkedInfo = each.value.rbac_authorization != null ? {
          authorizationType = "RBAC"
          resourceId        = each.value.rbac_authorization.resource_id
          credential = each.value.credential_name == null ? null : {
            referenceName = each.value.credential_name
          }
        } : null
      }
    }
  }
  create_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  delete_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  read_headers           = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
  response_export_values = ["*"]
  update_headers         = var.enable_telemetry ? { "User-Agent" : local.avm_azapi_header } : null
}
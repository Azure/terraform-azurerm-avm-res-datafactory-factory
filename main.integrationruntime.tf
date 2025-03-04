resource "azurerm_data_factory_integration_runtime_self_hosted" "this" {
  for_each = var.integration_runtime_self_hosted

  data_factory_id                              = azurerm_data_factory.this.id
  name                                         = each.value.name
  description                                  = each.value.description
  self_contained_interactive_authoring_enabled = each.value.self_contained_interactive_authoring_enabled

  dynamic "rbac_authorization" {
    for_each = each.value.rbac_authorization != null ? [each.value.rbac_authorization] : []

    content {
      resource_id = rbac_authorization.value.resource_id
    }
  }
}
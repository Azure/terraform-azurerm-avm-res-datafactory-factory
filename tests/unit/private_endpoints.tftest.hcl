mock_provider "azapi" {}
mock_provider "azurerm" {
  mock_resource "azurerm_data_factory" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.DataFactory/factories/test-factory"
    }
  }
  mock_resource "azurerm_private_endpoint" {
    defaults = {
      id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/privateEndpoints/test-endpoint"
    }
  }
}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  name                = "test-factory"
  location            = "eastus"
  resource_group_name = "test"
  enable_telemetry    = false
}

run "no_private_endpoints_by_default" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }

  assert {
    condition     = length(output.private_endpoints) == 0 && length(azurerm_management_lock.private_endpoints) == 0 && length(azurerm_role_assignment.private_endpoints) == 0
    error_message = "No private endpoint, lock or role assignment should be created by default."
  }
  assert {
    condition     = output.resource_id == azurerm_data_factory.this.id
    error_message = "The factory output must retain the existing resource address."
  }
}

run "managed_endpoint_defaults" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }
  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.0.4"
          }
        }
        lock = {
          kind = "CanNotDelete"
        }
        role_assignments = {
          reader = {
            role_definition_id_or_name = "Reader"
            principal_id               = "00000000-0000-0000-0000-000000000001"
          }
        }
      }
    }
  }

  assert {
    condition     = one(azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].private_service_connection[0].subresource_names) == "dataFactory" && azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].ip_configuration[0].member_name == "Azure Data Factory"
    error_message = "Omitted optional fields must preserve the existing factory subresource and member defaults."
  }
  assert {
    condition     = azurerm_management_lock.private_endpoints["endpoint"].name == "lock-CanNotDelete" && azurerm_management_lock.private_endpoints["endpoint"].scope == azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].id && azurerm_management_lock.private_endpoints["endpoint"].lock_level == "CanNotDelete"
    error_message = "The configured lock must be created on the managed endpoint with its default name."
  }
  assert {
    condition     = azurerm_role_assignment.private_endpoints[jsonencode(["endpoint", "reader"])].role_definition_name == "Reader" && azurerm_role_assignment.private_endpoints[jsonencode(["endpoint", "reader"])].scope == azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].id
    error_message = "A role definition name must be assigned at the managed endpoint scope."
  }
}

run "managed_endpoint_custom_settings" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }
  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"
        subresource_name              = "portal"
        private_dns_zone_resource_ids = ["/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/privateDnsZones/privatelink.adf.azure.com"]
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.0.5"
            member_name        = "portal"
          }
        }
        lock = {
          kind  = "ReadOnly"
          name  = "custom-lock"
          notes = "Endpoint protection"
        }
        role_assignments = {
          reader = {
            name                                   = "00000000-0000-0000-0000-000000000002"
            role_definition_id_or_name             = "/subscriptions/00000000-0000-0000-0000-000000000000/providers/Microsoft.Authorization/roleDefinitions/acdd72a7-3385-48ef-bd42-f606fba81ae7"
            principal_id                           = "00000000-0000-0000-0000-000000000001"
            description                            = "Endpoint reader"
            principal_type                         = "ServicePrincipal"
            skip_service_principal_aad_check       = true
            condition                              = "@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringEquals 'example'"
            condition_version                      = "2.0"
            delegated_managed_identity_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test"
          }
        }
      }
    }
  }

  assert {
    condition     = one(azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].private_service_connection[0].subresource_names) == "portal" && azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].ip_configuration[0].member_name == "portal" && azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].ip_configuration[0].subresource_name == "portal"
    error_message = "Custom subresource and member names must reach both connection and IP configuration."
  }
  assert {
    condition     = length(azurerm_private_endpoint.this_managed_dns_zone_groups["endpoint"].private_dns_zone_group) == 1 && length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 0
    error_message = "The existing managed DNS resource path must remain active."
  }
  assert {
    condition     = azurerm_management_lock.private_endpoints["endpoint"].name == "custom-lock" && azurerm_management_lock.private_endpoints["endpoint"].notes == "Endpoint protection" && azurerm_management_lock.private_endpoints["endpoint"].lock_level == "ReadOnly"
    error_message = "All configured lock settings must be retained."
  }
  assert {
    condition = alltrue([
      azurerm_role_assignment.private_endpoints[jsonencode(["endpoint", "reader"])].name == var.private_endpoints.endpoint.role_assignments.reader.name,
      azurerm_role_assignment.private_endpoints[jsonencode(["endpoint", "reader"])].role_definition_id == var.private_endpoints.endpoint.role_assignments.reader.role_definition_id_or_name,
      azurerm_role_assignment.private_endpoints[jsonencode(["endpoint", "reader"])].principal_id == var.private_endpoints.endpoint.role_assignments.reader.principal_id,
      azurerm_role_assignment.private_endpoints[jsonencode(["endpoint", "reader"])].description == var.private_endpoints.endpoint.role_assignments.reader.description,
      azurerm_role_assignment.private_endpoints[jsonencode(["endpoint", "reader"])].principal_type == var.private_endpoints.endpoint.role_assignments.reader.principal_type,
      azurerm_role_assignment.private_endpoints[jsonencode(["endpoint", "reader"])].skip_service_principal_aad_check,
      azurerm_role_assignment.private_endpoints[jsonencode(["endpoint", "reader"])].condition == var.private_endpoints.endpoint.role_assignments.reader.condition,
      azurerm_role_assignment.private_endpoints[jsonencode(["endpoint", "reader"])].condition_version == var.private_endpoints.endpoint.role_assignments.reader.condition_version,
      azurerm_role_assignment.private_endpoints[jsonencode(["endpoint", "reader"])].delegated_managed_identity_resource_id == var.private_endpoints.endpoint.role_assignments.reader.delegated_managed_identity_resource_id
    ])
    error_message = "Every private endpoint role assignment setting must reach the resource."
  }
}

run "unmanaged_endpoint_custom_settings" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }
  variables {
    private_endpoints_manage_dns_zone_group = false
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"
        subresource_name   = "portal"
        ip_configurations = {
          primary = {
            name               = "primary"
            private_ip_address = "10.0.0.6"
            member_name        = "portal"
          }
        }
        lock = {
          kind  = "ReadOnly"
          notes = "Unmanaged endpoint protection"
        }
        role_assignments = {
          reader = {
            role_definition_id_or_name = "Reader"
            principal_id               = "00000000-0000-0000-0000-000000000001"
          }
        }
      }
    }
  }

  assert {
    condition     = length(azurerm_private_endpoint.this_managed_dns_zone_groups) == 0 && one(azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].private_service_connection[0].subresource_names) == "portal" && azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].ip_configuration[0].member_name == "portal"
    error_message = "Custom settings must also reach the unmanaged endpoint without changing its resource address."
  }
  assert {
    condition     = azurerm_management_lock.private_endpoints["endpoint"].scope == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].id && azurerm_role_assignment.private_endpoints[jsonencode(["endpoint", "reader"])].scope == azurerm_private_endpoint.this_unmanaged_dns_zone_groups["endpoint"].id
    error_message = "Locks and role assignments must target the unmanaged endpoint when DNS management is disabled."
  }
}

run "invalid_subnet_id" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }
  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "invalid"
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_dns_zone_id" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }
  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id            = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"
        private_dns_zone_resource_ids = ["invalid"]
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_application_security_group_id" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }
  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"
        application_security_group_associations = {
          group = "invalid"
        }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

run "invalid_delegated_identity_id" {
  command = plan
  providers = {
    azapi   = azapi
    azurerm = azurerm
    modtm   = modtm
    random  = random
  }
  variables {
    private_endpoints = {
      endpoint = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"
        role_assignments = {
          reader = {
            role_definition_id_or_name             = "Reader"
            principal_id                           = "00000000-0000-0000-0000-000000000001"
            delegated_managed_identity_resource_id = "invalid"
          }
        }
      }
    }
  }
  expect_failures = [var.private_endpoints]
}

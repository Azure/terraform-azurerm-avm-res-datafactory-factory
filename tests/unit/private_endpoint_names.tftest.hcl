# Covers generated endpoint names without an Azure subscription.
mock_provider "azapi" {
  mock_data "azapi_client_config" {
    defaults = {
      subscription_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000"
    }
  }
}

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

variables {
  name                = "test-factory"
  location            = "eastus"
  resource_group_name = "test"
  enable_telemetry    = false
}

run "single_default_keeps_legacy_name" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm
  }
  variables {
    private_endpoints = {
      factory = { subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test" }
    }
  }
  assert {
    condition     = azurerm_private_endpoint.this_managed_dns_zone_groups["factory"].name == "pe-test-factory"
    error_message = "A single unnamed endpoint must retain its existing default name."
  }
}

run "two_managed_endpoints_get_distinct_names" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm
  }
  variables {
    private_endpoints = {
      factory = { subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test" }
      portal  = { subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test" }
    }
  }
  assert {
    condition = (
      length(azurerm_private_endpoint.this_managed_dns_zone_groups) == 2 &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["factory"].name == "pep-test-factory-factory-7b202d57f214" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["portal"].name == "pep-test-factory-portal-23f3fd77a464"
    )
    error_message = "Multiple unnamed managed endpoints must have stable, distinct names."
  }
}

run "two_unmanaged_endpoints_get_distinct_names" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm
  }
  variables {
    private_endpoints_manage_dns_zone_group = false
    private_endpoints = {
      factory = { subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test" }
      portal  = { subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test" }
    }
  }
  assert {
    condition = (
      length(azurerm_private_endpoint.this_unmanaged_dns_zone_groups) == 2 &&
      azurerm_private_endpoint.this_unmanaged_dns_zone_groups["factory"].name == "pep-test-factory-factory-7b202d57f214" &&
      azurerm_private_endpoint.this_unmanaged_dns_zone_groups["portal"].name == "pep-test-factory-portal-23f3fd77a464"
    )
    error_message = "The unmanaged DNS mode must use the same unique naming logic."
  }
}

run "explicit_name_preserves_existing_unnamed_endpoint" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm
  }
  variables {
    private_endpoints = {
      factory = { subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test" }
      portal = {
        name               = "pep-custom-portal"
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"
      }
    }
  }
  assert {
    condition = (
      azurerm_private_endpoint.this_managed_dns_zone_groups["factory"].name == "pe-test-factory" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["portal"].name == "pep-custom-portal"
    )
    error_message = "Explicit names must be respected without renaming the sole unnamed endpoint."
  }
}

run "truncated_and_sanitized_keys_remain_distinct" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm
  }
  variables {
    name = "factory-abcdefghijklmnopqrstuvwxyz-abcdefghijklmnopqrstuvwxyz"
    private_endpoints = {
      "long/key?one" = { subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test" }
      "long-key-one" = { subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test" }
    }
  }
  assert {
    condition = (
      length(azurerm_private_endpoint.this_managed_dns_zone_groups["long/key?one"].name) <= 64 &&
      length(azurerm_private_endpoint.this_managed_dns_zone_groups["long-key-one"].name) <= 64 &&
      can(regex("^[a-z0-9][a-z0-9_.-]*[a-z0-9_]$", azurerm_private_endpoint.this_managed_dns_zone_groups["long/key?one"].name)) &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["long/key?one"].name != azurerm_private_endpoint.this_managed_dns_zone_groups["long-key-one"].name
    )
    error_message = "Long or punctuation-heavy map keys must generate distinct, valid Azure endpoint names."
  }
}

run "different_resource_groups_keep_legacy_names" {
  command = apply
  providers = {
    azapi   = azapi
    azurerm = azurerm
  }
  variables {
    private_endpoints = {
      factory = {
        subnet_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"
        resource_group_name = "network-a"
      }
      portal = {
        subnet_resource_id  = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/test/providers/Microsoft.Network/virtualNetworks/test/subnets/test"
        resource_group_name = "network-b"
      }
    }
  }
  assert {
    condition = (
      azurerm_private_endpoint.this_managed_dns_zone_groups["factory"].name == "pe-test-factory" &&
      azurerm_private_endpoint.this_managed_dns_zone_groups["portal"].name == "pe-test-factory"
    )
    error_message = "Endpoints in different resource groups may share the legacy name without replacement."
  }
}

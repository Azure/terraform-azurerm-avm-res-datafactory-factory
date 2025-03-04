terraform {
  required_version = ">= 1.9, < 2.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.87"
    }
  }
}

provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

# Naming Module for Consistent Resource Names
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"
  prefix  = ["test"]
  suffix  = ["01"]
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  location = "southeastasia"
  name     = module.naming.resource_group.name
}

# Create Resource Group
resource "azurerm_resource_group" "host" {
  location = "southeastasia"
  name     = module.naming.resource_group.name
}

resource "azurerm_data_factory" "host" {
  location            = azurerm_resource_group.host.location
  name                = module.naming.data_factory.name
  resource_group_name = azurerm_resource_group.host.name
}

resource "azurerm_data_factory_integration_runtime_self_hosted" "host" {
  data_factory_id = azurerm_data_factory.host.id
  name            = module.naming.data_factory_integration_runtime_managed.name
}



module "df_with_integration_runtime_self_hosted" {
  source = "../../" # Adjust this path based on your module's location

  # Required variables (adjust values accordingly)
  name                = module.naming.data_factory.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  integration_runtime_self_hosted = {
    example = {
      name        = module.naming.data_factory_integration_runtime_managed.name
      description = "test description"
      rbac_authorization = {
        resource_id = azurerm_data_factory_integration_runtime_self_hosted.host.id
      }
    }
  }

}



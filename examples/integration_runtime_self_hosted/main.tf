terraform {
  required_version = ">= 1.9, < 2.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.5"
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

resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Naming Module for Consistent Resource Names
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  suffix = random_string.seed.result
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  location = "southeastasia"
  name     = "${module.naming.resource_group.name}-rg"
}

# Create Resource Group
resource "azurerm_resource_group" "host" {
  location = "southeastasia"
  name     = "${module.naming.resource_group.name}-host"
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

  location = azurerm_resource_group.rg.location
  # Required variables (adjust values accordingly)
  name                = "DataFactory-${module.naming.data_factory.name_unique}"
  resource_group_name = azurerm_resource_group.rg.name
  enable_telemetry    = false
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



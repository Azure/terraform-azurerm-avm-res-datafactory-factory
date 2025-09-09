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

# Single Naming Module for all resources
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"
}

# Create Resource Group with dynamically generated name
resource "azurerm_resource_group" "rg" {
  location = "eastasia"
  name     = module.naming.resource_group.name_unique
}

resource "random_string" "name_suffix" {
  length  = 5
  lower   = true
  numeric = true
  special = false
  upper   = false
}

# Create a Storage Account with dynamically generated name
resource "azurerm_storage_account" "storage" {
  account_replication_type = "ZRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.rg.location
  name                     = "test${random_string.name_suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
}

# Create an Azure File Share with dynamically generated name
resource "azurerm_storage_share" "fileshare" {
  name               = module.naming.storage_share.name
  quota              = 5
  storage_account_id = azurerm_storage_account.storage.id
}

module "df_with_linked_service" {
  source = "../../" # Adjust this path based on your module's location

  location = azurerm_resource_group.rg.location
  # Required variables (adjust values accordingly)
  name                = "DataFactory-${module.naming.data_factory.name_unique}"
  resource_group_name = azurerm_resource_group.rg.name
  enable_telemetry    = false
  linked_service_azure_file_storage = {
    example = {
      name              = module.naming.data_factory_linked_service_data_lake_storage_gen2.name
      connection_string = azurerm_storage_account.storage.primary_connection_string
    }
  }
}


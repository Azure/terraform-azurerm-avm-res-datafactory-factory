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

# Single Naming Module for all resources
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"

  prefix = ["test"]
  suffix = ["03"]
}

# Create Resource Group with dynamically generated name
resource "azurerm_resource_group" "rg" {
  location = "southeastasia"
  name     = module.naming.resource_group.name
}

# Create a Storage Account with dynamically generated name
resource "azurerm_storage_account" "storage" {
  account_replication_type = "ZRS"
  account_tier             = "Standard"
  location                 = azurerm_resource_group.rg.location
  name                     = module.naming.storage_account.name
  resource_group_name      = azurerm_resource_group.rg.name
}

# Create an Azure File Share with dynamically generated name
resource "azurerm_storage_share" "fileshare" {
  name                 = module.naming.storage_share.name
  quota                = 5
  storage_account_name = azurerm_storage_account.storage.name
}

module "df_with_linked_service" {
  source = "../../" # Adjust this path based on your module's location

  location = azurerm_resource_group.rg.location
  # Required variables (adjust values accordingly)
  name                = module.naming.data_factory.name
  resource_group_name = azurerm_resource_group.rg.name
  linked_service_azure_file_storage = {
    example = {
      name              = module.naming.data_factory_linked_service_data_lake_storage_gen2.name
      connection_string = azurerm_storage_account.storage.primary_connection_string
    }
  }
}


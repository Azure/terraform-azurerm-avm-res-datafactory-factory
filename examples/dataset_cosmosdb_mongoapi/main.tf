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
}

# Create Resource Group with dynamically generated name
resource "azurerm_resource_group" "rg" {
  location = "southeastasia"
  name     = module.naming.resource_group.name
}

module "basic" {
  source = "../../" # Adjust this path based on your module's location

  location = azurerm_resource_group.rg.location
  # Required variables (adjust values accordingly)
  name                = "DataFactory-${module.naming.data_factory.name_unique}"
  resource_group_name = azurerm_resource_group.rg.name
  dataset_cosmosdb_mongoapi = {
    dataset_1 = {
      name                = "cosmosdbmongoapitest"
      linked_service_name = "ls-cosmosdb-mongoapi-test"
      collection_name     = "collection-1"
      annotations         = ["annotation1"]
      description         = "some-description"
      folder              = "folder-1"
      parameters = {
        "param1" = "value1"
      }
    }
  }
  linked_service_cosmosdb_mongoapi = {
    cosmosdb_ls_1 = {
      name              = "ls-cosmosdb-mongoapi-test"
      connection_string = "mongodb://acc:pass@foobar.documents.azure.com:10255"
      database          = "mydbname"
    }
  }
}

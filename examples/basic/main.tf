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

module "basic" {
  source = "../../" # Adjust this path based on your module's location

  location = azurerm_resource_group.rg.location
  # Required variables (adjust values accordingly)
  name                = module.naming.data_factory.name
  resource_group_name = azurerm_resource_group.rg.name
}
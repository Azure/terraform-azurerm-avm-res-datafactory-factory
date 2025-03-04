<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the Azure Data Factory with Linked Service.

```hcl
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
  prefix  = ["test"]
  suffix  = ["03"]
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

  # Required variables (adjust values accordingly)
  name                = module.naming.data_factory.name
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  linked_service_azure_file_storage = {
    example = {
      name              = module.naming.data_factory_linked_service_data_lake_storage_gen2.name
      connection_string = azurerm_storage_account.storage.primary_connection_string
    }
  }

}

```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.87)

## Providers

The following providers are used by this module:

- <a name="provider_azurerm"></a> [azurerm](#provider\_azurerm) (>= 3.87)

## Resources

The following resources are used by this module:

- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_storage_account.storage](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_account) (resource)
- [azurerm_storage_share.fileshare](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/storage_share) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_df_with_linked_service"></a> [df\_with\_linked\_service](#module\_df\_with\_linked\_service)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.3.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->
<!-- BEGIN_TF_DOCS -->
# Default example

This deploys the Azure Data Factory with Integration Runtime Self Hosted Settings.

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

# Naming Module for Consistent Resource Names
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.3.0"

  prefix = ["test"]
  suffix = ["01"]
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

  location = azurerm_resource_group.rg.location
  # Required variables (adjust values accordingly)
  name                = module.naming.data_factory.name
  resource_group_name = azurerm_resource_group.rg.name
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


```

<!-- markdownlint-disable MD033 -->
## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (>= 1.9, < 2.0)

- <a name="requirement_azurerm"></a> [azurerm](#requirement\_azurerm) (>= 3.87)

## Resources

The following resources are used by this module:

- [azurerm_data_factory.host](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_factory) (resource)
- [azurerm_data_factory_integration_runtime_self_hosted.host](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/data_factory_integration_runtime_self_hosted) (resource)
- [azurerm_resource_group.host](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)
- [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) (resource)

<!-- markdownlint-disable MD013 -->
## Required Inputs

No required inputs.

## Optional Inputs

No optional inputs.

## Outputs

No outputs.

## Modules

The following Modules are called:

### <a name="module_df_with_integration_runtime_self_hosted"></a> [df\_with\_integration\_runtime\_self\_hosted](#module\_df\_with\_integration\_runtime\_self\_hosted)

Source: ../../

Version:

### <a name="module_naming"></a> [naming](#module\_naming)

Source: Azure/naming/azurerm

Version: 0.3.0

<!-- markdownlint-disable-next-line MD041 -->
## Data Collection

The software may collect information about you and your use of the software and send it to Microsoft. Microsoft may use this information to provide services and improve our products and services. You may turn off the telemetry as described in the repository. There are also some features in the software that may enable you and Microsoft to collect data from users of your applications. If you use these features, you must comply with applicable law, including providing appropriate notices to users of your applications together with a copy of Microsoft’s privacy statement. Our privacy statement is located at <https://go.microsoft.com/fwlink/?LinkID=824704>. You can learn more about data collection and use in the help documentation and our privacy statement. Your use of the software operates as your consent to these practices.
<!-- END_TF_DOCS -->
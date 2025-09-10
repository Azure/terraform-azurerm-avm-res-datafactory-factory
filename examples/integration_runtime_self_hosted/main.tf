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
  numeric = false
  special = false
  upper   = false
}

# Naming Module for Consistent Resource Names
module "naming" {
  source  = "Azure/naming/azurerm"
  version = "0.4.2"

  suffix = [random_string.suffix.result]
}

# Create Resource Group
resource "azurerm_resource_group" "rg" {
  location = "southeastasia"
  name     = "${module.naming.resource_group.name_unique}-rg"
}

# Create Resource Group
resource "azurerm_resource_group" "host" {
  location = "southeastasia"
  name     = "${module.naming.resource_group.name_unique}-host"
}

resource "azurerm_virtual_network" "example" {
  location            = azurerm_resource_group.host.location
  name                = "hostvnet"
  resource_group_name = azurerm_resource_group.host.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "example" {
  address_prefixes     = ["10.0.2.0/24"]
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.host.name
  virtual_network_name = azurerm_virtual_network.example.name
}

resource "azurerm_public_ip" "example" {
  allocation_method   = "Static"
  location            = azurerm_resource_group.host.location
  name                = "pip"
  resource_group_name = azurerm_resource_group.host.name
}

resource "azurerm_network_interface" "example" {
  location            = azurerm_resource_group.host.location
  name                = "nic"
  resource_group_name = azurerm_resource_group.host.name

  ip_configuration {
    name                          = "internal"
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
    subnet_id                     = azurerm_subnet.example.id
  }
}

resource "random_password" "pass" {
  length  = 15
  lower   = true
  numeric = true
  special = false
  upper   = true
}

resource "azurerm_windows_virtual_machine" "bootstrap" {
  admin_password = random_password.pass.result
  admin_username = "adminuser"
  location       = azurerm_resource_group.host.location
  name           = "vm${random_string.suffix.result}"
  network_interface_ids = [
    azurerm_network_interface.example.id,
  ]
  resource_group_name = azurerm_resource_group.host.name
  size                = "Standard_F2"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    offer     = "WindowsServer"
    publisher = "MicrosoftWindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "bootstrap" {
  name                 = "bootstrapExt"
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
  virtual_machine_id   = azurerm_windows_virtual_machine.bootstrap.id
  settings = jsonencode({
    "fileUris"         = ["https://raw.githubusercontent.com/Azure/azure-quickstart-templates/5661e3290f1d072195d26a5fc9d52bb372a55f48/quickstarts/microsoft.compute/vms-with-selfhost-integration-runtime/gatewayInstall.ps1"],
    "commandToExecute" = "powershell -ExecutionPolicy Unrestricted -File gatewayInstall.ps1 ${azurerm_data_factory_integration_runtime_self_hosted.host.primary_authorization_key} && timeout /t 120"
  })
}

resource "azurerm_user_assigned_identity" "example" {
  location            = azurerm_resource_group.host.location
  name                = module.naming.data_factory.name_unique
  resource_group_name = azurerm_resource_group.host.name
}

resource "azurerm_data_factory" "host" {
  location            = azurerm_resource_group.host.location
  name                = module.naming.data_factory.name_unique
  resource_group_name = azurerm_resource_group.host.name
}

resource "azurerm_role_assignment" "target" {
  principal_id         = azurerm_user_assigned_identity.example.principal_id
  scope                = azurerm_data_factory.host.id
  role_definition_name = "Contributor"
}

resource "azurerm_data_factory_integration_runtime_self_hosted" "host" {
  data_factory_id = azurerm_data_factory.host.id
  name            = module.naming.data_factory_integration_runtime_managed.name_unique
}

module "df_with_integration_runtime_self_hosted" {
  source = "../../" # Adjust this path based on your module's location

  location = azurerm_resource_group.rg.location
  # Required variables (adjust values accordingly)
  name                = "DataFactory-${module.naming.data_factory.name_unique}"
  resource_group_name = azurerm_resource_group.rg.name
  credential_user_managed_identity = {
    example = {
      name        = "credential-${azurerm_user_assigned_identity.example.name}"
      identity_id = azurerm_user_assigned_identity.example.id
      annotations = ["1"]
      description = "ORIGINAL DESCRIPTION"
    }
  }
  enable_telemetry = false
  integration_runtime_self_hosted = {
    example = {
      name        = module.naming.data_factory_integration_runtime_managed.name
      description = "test description"
      rbac_authorization = {
        resource_id     = azurerm_data_factory_integration_runtime_self_hosted.host.id
        credential_name = "credential-${azurerm_user_assigned_identity.example.name}"
      }
    }
  }
  managed_identities = {
    system_assigned = false
    user_assigned_resource_ids = [
      azurerm_user_assigned_identity.example.id
    ]
  }

  depends_on = [
    azurerm_role_assignment.target,
    azurerm_virtual_machine_extension.bootstrap,
  ]
}



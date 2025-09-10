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
  name                = "hostvnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.host.location
  resource_group_name = azurerm_resource_group.host.name
}

resource "azurerm_subnet" "example" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.host.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_public_ip" "example" {
  name                = "pip"
  location            = azurerm_resource_group.host.location
  resource_group_name = azurerm_resource_group.host.name
  allocation_method   = "Static"
}

resource "azurerm_network_interface" "example" {
  name                = "nic"
  location            = azurerm_resource_group.host.location
  resource_group_name = azurerm_resource_group.host.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.example.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.example.id
  }
}

resource "random_password" "pass" {
  length  = 15
  upper   = true
  lower   = true
  special = false
  numeric = true
}

resource "azurerm_virtual_machine" "bootstrap" {
  name                          = "vm"
  location                      = azurerm_resource_group.host.location
  resource_group_name           = azurerm_resource_group.host.name
  network_interface_ids         = [azurerm_network_interface.example.id]
  vm_size                       = "Standard_F4"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk1"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "bootstrapvm"
    admin_username = "testadmin"
    admin_password = random_password.pass.result
  }

  os_profile_windows_config {
    timezone           = "Pacific Standard Time"
    provision_vm_agent = true
  }
}

resource "azurerm_virtual_machine_extension" "bootstrap" {
  name                 = "bootstrapExt"
  virtual_machine_id   = azurerm_virtual_machine.bootstrap.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.10"
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
  scope                = azurerm_data_factory.host.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.example.principal_id
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
  managed_identities = {
    system_assigned = false
    user_assigned_resource_ids = [
      azurerm_user_assigned_identity.example.id
    ]
  }
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
  depends_on = [
    azurerm_role_assignment.target,
    azurerm_virtual_machine_extension.bootstrap,
  ]
}



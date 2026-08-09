# Tests Azure File Storage linked service configuration.
mock_provider "azurerm" {}
mock_provider "azapi" {}
mock_provider "modtm" {}
mock_provider "random" {}

variables {
  name                = "df-test-linked"
  resource_group_name = "rg-test-linked"
  location            = "eastus"
  enable_telemetry    = false

  linked_service_azure_file_storage = {
    example = {
      name              = "ls-fileshare-test"
      connection_string = "DefaultEndpointsProtocol=https;AccountName=teststorage;AccountKey=dGVzdGtleQ==;EndpointSuffix=core.windows.net"
    }
  }
}

run "plan_linked_service" {
  command = plan
}

# Tests the new resource_types, retry, and timeouts variables introduced
# to satisfy AVM specs TFFR6 and TFFR7.
variables {
  name                = "df-test-overrides"
  resource_group_name = "rg-test-overrides"
  location            = "eastus"
  enable_telemetry    = false

  # TFFR6: consumers can pin specific API versions per azapi resource type.
  resource_types = {
    data_factory_datasets             = "Microsoft.DataFactory/factories/datasets@2018-06-01"
    data_factory_integration_runtimes = "Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01"
  }

  # TFFR7: retry and timeouts are wired through to every azapi resource.
  retry = {
    error_message_regex  = ["ResourceNotFound", "ServiceUnavailable"]
    interval_seconds     = 5
    max_interval_seconds = 30
  }

  timeouts = {
    create = "30m"
    read   = "5m"
    update = "30m"
    delete = "30m"
  }

  # Exercise the dataset with the overridden API type string.
  dataset_cosmosdb_mongoapi = {
    dataset_1 = {
      name                = "cosmosdbmongoapitest"
      linked_service_name = "ls-test"
      collection_name     = "collection-1"
    }
  }

  linked_service_cosmosdb_mongoapi = {
    ls_1 = {
      name              = "ls-test"
      connection_string = "mongodb://acc:pass@foobar.documents.azure.com:10255"
      database          = "mydbname"
    }
  }
}

run "plan_resource_types_and_retry_timeouts" {
  command = plan
}

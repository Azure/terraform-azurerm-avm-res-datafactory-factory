# Tests a CosmosDB MongoDB API dataset with a linked service.
variables {
  name                = "df-test-dataset"
  resource_group_name = "rg-test-dataset"
  location            = "eastus"
  enable_telemetry    = false

  dataset_cosmosdb_mongoapi = {
    dataset_1 = {
      name                = "cosmosdbmongoapitest"
      linked_service_name = "ls-cosmosdb-test"
      collection_name     = "collection-1"
      annotations         = ["annotation1"]
      description         = "test description"
      folder              = "folder-1"
      parameters = {
        "param1" = "value1"
      }
    }
  }

  linked_service_cosmosdb_mongoapi = {
    cosmosdb_ls_1 = {
      name              = "ls-cosmosdb-test"
      connection_string = "mongodb://acc:pass@foobar.documents.azure.com:10255"
      database          = "mydbname"
    }
  }
}

run "plan_dataset_cosmosdb_mongoapi" {
  command = plan
}

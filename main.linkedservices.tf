resource "azurerm_data_factory_linked_service_azure_blob_storage" "this" {
  for_each = var.linked_service_azure_blob_storage

  data_factory_id            = azurerm_data_factory.this.id
  name                       = each.value.name
  additional_properties      = each.value.additional_properties
  annotations                = each.value.annotations
  connection_string          = each.value.connection_string
  connection_string_insecure = each.value.connection_string_insecure
  description                = each.value.description
  integration_runtime_name   = each.value.integration_runtime_name
  parameters                 = each.value.parameters
  sas_uri                    = each.value.sas_uri
  service_endpoint           = each.value.service_endpoint
  service_principal_id       = each.value.service_principal_id
  service_principal_key      = each.value.service_principal_key
  storage_kind               = each.value.storage_kind
  tenant_id                  = each.value.tenant_id
  use_managed_identity       = each.value.use_managed_identity

  dynamic "key_vault_sas_token" {
    for_each = each.value.key_vault_sas_token != null ? [each.value.key_vault_sas_token] : []

    content {
      linked_service_name = key_vault_sas_token.value.linked_service_name
      secret_name         = key_vault_sas_token.value.secret_name
    }
  }
  dynamic "service_principal_linked_key_vault_key" {
    for_each = each.value.service_principal_linked_key_vault_key != null ? [each.value.service_principal_linked_key_vault_key] : []

    content {
      linked_service_name = service_principal_linked_key_vault_key.value.linked_service_name
      secret_name         = service_principal_linked_key_vault_key.value.secret_name
    }
  }
}

resource "azurerm_data_factory_linked_service_azure_databricks" "this" {
  for_each = var.linked_service_databricks

  adb_domain      = each.value.adb_domain
  data_factory_id = azurerm_data_factory.this.id
  name            = each.value.name
  # Authentication Options (Only one can be specified)
  access_token          = each.value.access_token
  additional_properties = each.value.additional_properties
  annotations           = each.value.annotations
  description           = each.value.description
  # Cluster Integration Options (Only one can be specified)
  existing_cluster_id        = each.value.existing_cluster_id
  integration_runtime_name   = each.value.integration_runtime_name
  msi_work_space_resource_id = each.value.msi_work_space_resource_id
  parameters                 = each.value.parameters

  dynamic "instance_pool" {
    for_each = each.value.instance_pool != null ? [each.value.instance_pool] : []

    content {
      cluster_version       = instance_pool.value.cluster_version
      instance_pool_id      = instance_pool.value.instance_pool_id
      max_number_of_workers = instance_pool.value.max_number_of_workers
      min_number_of_workers = instance_pool.value.min_number_of_workers
    }
  }
  dynamic "key_vault_password" {
    for_each = each.value.key_vault_password != null ? [each.value.key_vault_password] : []

    content {
      linked_service_name = key_vault_password.value.linked_service_name
      secret_name         = key_vault_password.value.secret_name
    }
  }
  dynamic "new_cluster_config" {
    for_each = each.value.new_cluster_config != null ? [each.value.new_cluster_config] : []

    content {
      cluster_version             = new_cluster_config.value.cluster_version
      node_type                   = new_cluster_config.value.node_type
      custom_tags                 = new_cluster_config.value.custom_tags
      driver_node_type            = new_cluster_config.value.driver_node_type
      init_scripts                = new_cluster_config.value.init_scripts
      log_destination             = new_cluster_config.value.log_destination
      max_number_of_workers       = new_cluster_config.value.max_number_of_workers
      min_number_of_workers       = new_cluster_config.value.min_number_of_workers
      spark_config                = new_cluster_config.value.spark_config
      spark_environment_variables = new_cluster_config.value.spark_environment_variables
    }
  }
}

resource "azurerm_data_factory_linked_service_azure_file_storage" "this" {
  for_each = var.linked_service_azure_file_storage

  connection_string        = each.value.connection_string
  data_factory_id          = azurerm_data_factory.this.id
  name                     = each.value.name
  additional_properties    = each.value.additional_properties
  annotations              = each.value.annotations
  description              = each.value.description
  file_share               = each.value.file_share
  host                     = each.value.host
  integration_runtime_name = each.value.integration_runtime_name
  parameters               = each.value.parameters
  password                 = each.value.password
  user_id                  = each.value.user_id

  dynamic "key_vault_password" {
    for_each = each.value.key_vault_password != null ? [each.value.key_vault_password] : []

    content {
      linked_service_name = key_vault_password.value.linked_service_name
      secret_name         = key_vault_password.value.secret_name
    }
  }
}

resource "azurerm_data_factory_linked_service_azure_sql_database" "this" {
  for_each = var.linked_service_azure_sql_database

  data_factory_id          = azurerm_data_factory.this.id
  name                     = each.value.name
  additional_properties    = each.value.additional_properties
  annotations              = each.value.annotations
  connection_string        = each.value.connection_string
  description              = each.value.description
  integration_runtime_name = each.value.integration_runtime_name
  parameters               = each.value.parameters
  service_principal_id     = each.value.service_principal_id
  service_principal_key    = each.value.service_principal_key
  tenant_id                = each.value.tenant_id
  use_managed_identity     = each.value.use_managed_identity

  dynamic "key_vault_connection_string" {
    for_each = each.value.key_vault_connection_string != null ? [each.value.key_vault_connection_string] : []

    content {
      linked_service_name = key_vault_connection_string.value.linked_service_name
      secret_name         = key_vault_connection_string.value.secret_name
    }
  }
  dynamic "key_vault_password" {
    for_each = each.value.key_vault_password != null ? [each.value.key_vault_password] : []

    content {
      linked_service_name = key_vault_password.value.linked_service_name
      secret_name         = key_vault_password.value.secret_name
    }
  }
}

resource "azurerm_data_factory_linked_service_data_lake_storage_gen2" "this" {
  for_each = var.linked_service_data_lake_storage_gen2

  data_factory_id          = azurerm_data_factory.this.id
  name                     = each.value.name
  url                      = each.value.url
  additional_properties    = each.value.additional_properties
  annotations              = each.value.annotations
  description              = each.value.description
  integration_runtime_name = each.value.integration_runtime_name
  parameters               = each.value.parameters
  service_principal_id     = each.value.service_principal_id
  service_principal_key    = each.value.service_principal_key
  storage_account_key      = each.value.storage_account_key
  tenant                   = each.value.tenant
  use_managed_identity     = each.value.use_managed_identity
}

resource "azurerm_data_factory_linked_service_key_vault" "this" {
  for_each = var.linked_service_key_vault

  data_factory_id          = azurerm_data_factory.this.id
  key_vault_id             = each.value.key_vault_id
  name                     = each.value.name
  additional_properties    = each.value.additional_properties
  annotations              = each.value.annotations
  description              = each.value.description
  integration_runtime_name = each.value.integration_runtime_name
  parameters               = each.value.parameters
}
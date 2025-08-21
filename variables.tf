########## Required variables
variable "location" {
  type        = string
  description = "The Azure region where this and supporting resources should be deployed."
  nullable    = false
}

variable "name" {
  type        = string
  description = "The name of the this resource."

  validation {
    condition     = can(regex("^[-A-Za-z0-9]{1,63}$", var.name))
    error_message = "The name must be between 1 and 63 characters long and can only contain alphanumerics and hyphens."
  }
}

variable "resource_group_name" {
  type        = string
  description = "The resource group where the resources will be deployed."
}

variable "credential_service_principal" {
  type = map(object({
    name                 = string
    data_factory_id      = optional(string)
    tenant_id            = string
    service_principal_id = string
    annotations          = optional(list(string), null)
    description          = optional(string, null)

    service_principal_key = optional(object({
      linked_service_name = string
      secret_name         = string
      secret_version      = optional(string, null)
    }), null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of Azure Data Factory Credentials, where each key represents a unique configuration.
Each object in the map consists of the following properties:

- `name` - (Required) The unique name of the credential.
- `data_factory_id` - (Required) The ID of the Data Factory where the credential is associated.
- `tenant_id` - (Required) The Tenant ID of the Service Principal.
- `service_principal_id` - (Required) The Client ID of the Service Principal.
- `annotations` - (Optional) A list of tags to annotate the credential.
- `description` - (Optional) A description of the credential.
- `service_principal_key` - (Optional) A block defining the service principal key details.
  - `linked_service_name` - (Required) The name of the Linked Service to use for the Service Principal Key.
  - `secret_name` - (Required) The name of the Secret in the Key Vault.
  - `secret_version` - (Optional) The version of the Secret in the Key Vault.
DESCRIPTION
}

variable "credential_user_managed_identity" {
  type = map(object({
    name            = string
    data_factory_id = optional(string)
    identity_id     = string
    annotations     = optional(list(string), null)
    description     = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of Azure Data Factory Credentials using User Assigned Managed Identity, where each key represents a unique configuration.
Each object in the map consists of the following properties:

- `name` - (Required) The unique name of the credential.
- `data_factory_id` - (Required) The ID of the Data Factory where the credential is associated.
- `identity_id` - (Required) The Resource ID of an existing User Assigned Managed Identity. **Attempting to create a Credential resource without first assigning the identity to the parent Data Factory will result in an Azure API error.**
- `annotations` - (Optional) A list of tags to annotate the credential. **Manually altering the resource may cause annotations to be lost.**
- `description` - (Optional) A description of the credential.
DESCRIPTION
}

variable "customer_managed_key_id" {
  type        = string
  default     = null
  description = "Specifies the Azure Key Vault Key ID to be used as the Customer Managed Key (CMK). Required with user assigned identity."
}

variable "customer_managed_key_identity_id" {
  type        = string
  default     = null
  description = "Specifies the ID of the user assigned identity associated with the Customer Managed Key. Must be supplied if customer_managed_key_id is set."
}

variable "diagnostic_settings" {
  type = map(object({
    name                                     = optional(string, null)
    log_categories                           = optional(set(string), [])
    log_groups                               = optional(set(string), ["allLogs"])
    metric_categories                        = optional(set(string), ["AllMetrics"])
    log_analytics_destination_type           = optional(string, "Dedicated")
    workspace_resource_id                    = optional(string, null)
    storage_account_resource_id              = optional(string, null)
    event_hub_authorization_rule_resource_id = optional(string, null)
    event_hub_name                           = optional(string, null)
    marketplace_partner_resource_id          = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of diagnostic settings to create on the Key Vault. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the diagnostic setting. One will be generated if not set, however this will not be unique if you want to create multiple diagnostic setting resources.
- `log_categories` - (Optional) A set of log categories to send to the log analytics workspace. Defaults to `[]`.
- `log_groups` - (Optional) A set of log groups to send to the log analytics workspace. Defaults to `["allLogs"]`.
- `metric_categories` - (Optional) A set of metric categories to send to the log analytics workspace. Defaults to `["AllMetrics"]`.
- `log_analytics_destination_type` - (Optional) The destination type for the diagnostic setting. Possible values are `Dedicated` and `AzureDiagnostics`. Defaults to `Dedicated`.
- `workspace_resource_id` - (Optional) The resource ID of the log analytics workspace to send logs and metrics to.
- `storage_account_resource_id` - (Optional) The resource ID of the storage account to send logs and metrics to.
- `event_hub_authorization_rule_resource_id` - (Optional) The resource ID of the event hub authorization rule to send logs and metrics to.
- `event_hub_name` - (Optional) The name of the event hub. If none is specified, the default event hub will be selected.
- `marketplace_partner_resource_id` - (Optional) The full ARM resource ID of the Marketplace resource to which you would like to send Diagnostic LogsLogs.
DESCRIPTION
  nullable    = false

  validation {
    condition     = alltrue([for _, v in var.diagnostic_settings : contains(["Dedicated", "AzureDiagnostics"], v.log_analytics_destination_type)])
    error_message = "Log analytics destination type must be one of: 'Dedicated', 'AzureDiagnostics'."
  }
  validation {
    condition = alltrue(
      [
        for _, v in var.diagnostic_settings :
        v.workspace_resource_id != null || v.storage_account_resource_id != null || v.event_hub_authorization_rule_resource_id != null || v.marketplace_partner_resource_id != null
      ]
    )
    error_message = "At least one of `workspace_resource_id`, `storage_account_resource_id`, `marketplace_partner_resource_id`, or `event_hub_authorization_rule_resource_id`, must be set."
  }
}

variable "enable_telemetry" {
  type        = bool
  default     = true
  description = <<DESCRIPTION
This variable controls whether or not telemetry is enabled for the module.
For more information see <https://aka.ms/avm/telemetryinfo>.
If it is set to false, then no telemetry will be collected.
DESCRIPTION
  nullable    = false
}

variable "github_configuration" {
  type = object({
    account_name       = string
    branch_name        = string
    git_url            = optional(string, null)
    repository_name    = string
    root_folder        = string
    publishing_enabled = optional(bool, true)
  })
  default     = null
  description = <<DESCRIPTION
Defines the GitHub configuration for the Data Factory.
- account_name: Specifies the GitHub account name.
- branch_name: Specifies the branch of the repository to get code from.
- git_url: Specifies the GitHub Enterprise host name. Defaults to https://github.com for open source repositories.
- repository_name: Specifies the name of the git repository.
- root_folder: Specifies the root folder within the repository. Set to / for the top level.
- publishing_enabled: Is automated publishing enabled? Defaults to true.
**You must log in to the Data Factory management UI to complete the authentication to the GitHub repository.**
DESCRIPTION
}

variable "global_parameters" {
  type = list(object({
    name  = string
    type  = string
    value = any
  }))
  default     = []
  description = <<DESCRIPTION
Defines a list of global parameters for the Data Factory.
- name: Specifies the global parameter name.
- type: Specifies the global parameter type. Possible values: Array, Bool, Float, Int, Object, or String.
- value: Specifies the global parameter value.
**For type Array and Object, it is recommended to use jsonencode() for the value.**
DESCRIPTION
}

variable "integration_runtime_self_hosted" {
  type = map(object({
    data_factory_id                              = optional(string)
    name                                         = string
    description                                  = optional(string, null)
    self_contained_interactive_authoring_enabled = optional(bool, null)
    rbac_authorization = optional(object({
      resource_id = string
    }), null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of Azure Data Factory Self-hosted Integration Runtimes, where each key represents a unique configuration. Each object in the map consists of the following properties:

- `data_factory_id` - (Required) The ID of the Data Factory where the integration runtime is associated.
- `name` - (Required) The unique name of the integration runtime. Changing this forces a new resource to be created.
- `description` - (Optional) A description of the integration runtime.
- `self_contained_interactive_authoring_enabled` - (Optional) Specifies whether to enable interactive authoring when the self-hosted integration runtime cannot establish a connection with Azure Relay.
- `rbac_authorization` - (Optional) Defines RBAC authorization settings. Changing this forces a new resource to be created.
  - `resource_id` - (Required) The resource identifier of the integration runtime to be shared.
  **Note:** RBAC Authorization creates a linked Self-hosted Integration Runtime targeting the Shared Self-hosted Integration Runtime in `resource_id`. The linked Self-hosted Integration Runtime requires Contributor access to the Shared Self-hosted Data Factory.
DESCRIPTION
}

variable "linked_service_azure_blob_storage" {
  type = map(object({
    name                       = string
    description                = optional(string, null)
    integration_runtime_name   = optional(string, null)
    annotations                = optional(list(string), null)
    parameters                 = optional(map(string), null)
    additional_properties      = optional(map(string), null)
    connection_string          = optional(string, null)
    connection_string_insecure = optional(string, null)
    sas_uri                    = optional(string, null)
    service_endpoint           = optional(string, null)
    use_managed_identity       = optional(bool, null)
    service_principal_id       = optional(string, null)
    service_principal_key      = optional(string, null)
    storage_kind               = optional(string, null)
    tenant_id                  = optional(string, null)

    # Key Vault SAS Token (Optional)
    key_vault_sas_token = optional(object({
      linked_service_name = string
      secret_name         = string
    }), null)

    # Service Principal Linked Key Vault Key (Optional)
    service_principal_linked_key_vault_key = optional(object({
      linked_service_name = string
      secret_name         = string
    }), null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of Azure Blob Storage linked services, where each key represents a unique linked service configuration. Each object in the map consists of the following properties:

- `name` - (Required) Specifies the name of the Azure Data Factory Linked Service.
- `description` - (Optional) A description for the linked service.
- `integration_runtime_name` - (Optional) The integration runtime reference associated with the linked service.
- `annotations` - (Optional) A list of annotations (tags) for additional metadata.
- `parameters` - (Optional) A map of parameters to associate with the linked service.
- `additional_properties` - (Optional) Additional custom properties for the linked service.
### Authentication Options (Only one can be set):
- `connection_string` - (Optional) The secure connection string for the storage account. **Conflicts with** `connection_string_insecure`, `sas_uri`, and `service_endpoint`.
- `connection_string_insecure` - (Optional) The connection string sent insecurely. **Conflicts with** `connection_string`, `sas_uri`, and `service_endpoint`.
- `sas_uri` - (Optional) The Shared Access Signature (SAS) URI for authentication. **Conflicts with** `connection_string`, `connection_string_insecure`, and `service_endpoint`.
- `service_endpoint` - (Optional) The Service Endpoint for direct connectivity. **Conflicts with** `connection_string`, `connection_string_insecure`, and `sas_uri`.
### Identity Options:
- `use_managed_identity` - (Optional) Whether to use a managed identity for authentication.
- `service_principal_id` - (Optional) The service principal ID for authentication.
- `service_principal_key` - (Optional) The service principal key (password) for authentication.
- `tenant_id` - (Optional) The tenant ID for authentication.
### Storage Options:
- `storage_kind` - (Optional) The kind of storage account. Allowed values: `Storage`, `StorageV2`, `BlobStorage`, `BlockBlobStorage`.
### Key Vault Options:
- `key_vault_sas_token` - (Optional) A Key Vault SAS Token object containing:
  - `linked_service_name` - The name of the existing Key Vault Linked Service.
  - `secret_name` - The name of the secret in Azure Key Vault that stores the SAS token.
- `service_principal_linked_key_vault_key` - (Optional) A Key Vault object for storing the Service Principal Key:
  - `linked_service_name` - The name of the existing Key Vault Linked Service.
  - `secret_name` - The name of the secret in Azure Key Vault that stores the Service Principal Key.
DESCRIPTION
}

variable "linked_service_azure_file_storage" {
  type = map(object({
    name                     = string
    data_factory_id          = optional(string)
    description              = optional(string, null)
    host                     = optional(string, null)
    integration_runtime_name = optional(string, null)
    annotations              = optional(list(string), null)
    parameters               = optional(map(string), null)
    password                 = optional(string, null)
    user_id                  = optional(string, null)
    additional_properties    = optional(map(string), null)
    connection_string        = string
    file_share               = optional(string, null)
    key_vault_password = optional(object({
      linked_service_name = string
      secret_name         = string
    }), null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of Azure Data Factory Linked Services for Azure File Storage, where each key represents a unique configuration.
Each object in the map consists of the following properties:

- `name` - (Required) The unique name of the linked service.
- `data_factory_id` - (Required) The ID of the Data Factory where the linked service is associated.
- `description` - (Optional) A description of the linked service.
- `host` - (Optional) The Host name of the server.
- `integration_runtime_name` - (Optional) The integration runtime reference.
- `annotations` - (Optional) A list of tags to annotate the linked service.
- `parameters` - (Optional) A map of parameters.
- `password` - (Optional) The password to log in to the server.
- `user_id` - (Optional) The user ID to log in to the server.
- `additional_properties` - (Optional) Additional custom properties.
- `connection_string` - (Required) The connection string.
- `file_share` - (Optional) The name of the file share.

### Key Vault Password Block:
- `key_vault_password` - (Optional) Use an existing Key Vault to store the Azure File Storage password.
  - `linked_service_name` - (Required) The name of the Key Vault Linked Service.
  - `secret_name` - (Required) The secret storing the Azure File Storage password.
DESCRIPTION
}

variable "linked_service_azure_sql_database" {
  type = map(object({
    name                     = string
    data_factory_id          = optional(string)
    connection_string        = optional(string, null)
    use_managed_identity     = optional(bool, null)
    service_principal_id     = optional(string, null)
    service_principal_key    = optional(string, null)
    tenant_id                = optional(string, null)
    description              = optional(string, null)
    integration_runtime_name = optional(string, null)
    annotations              = optional(list(string), null)
    parameters               = optional(map(string), null)
    additional_properties    = optional(map(string), null)
    credential_name          = optional(string, null)

    key_vault_connection_string = optional(object({
      linked_service_name = string
      secret_name         = string
    }), null)

    key_vault_password = optional(object({
      linked_service_name = string
      secret_name         = string
    }), null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of Azure Data Factory Linked Services for Azure SQL Database, where each key represents a unique configuration.
Each object in the map consists of the following properties:

- `name` - (Required) The unique name of the linked service.
- `data_factory_id` - (Required) The ID of the Data Factory where the linked service is associated.
- `connection_string` - (Optional) The connection string used to authenticate with Azure SQL Database. **Exactly one of** `connection_string` **or** `key_vault_connection_string` **must be specified.**
- `use_managed_identity` - (Optional) Whether to use the Data Factory's managed identity for authentication. **Incompatible with** `service_principal_id` **and** `service_principal_key`.
- `service_principal_id` - (Optional) The service principal ID for authentication. **Required if** `service_principal_key` **is set.**
- `service_principal_key` - (Optional) The service principal key (password) for authentication. **Required if** `service_principal_id` **is set.**
- `tenant_id` - (Optional) The tenant ID for authentication.
- `description` - (Optional) A description of the linked service.
- `integration_runtime_name` - (Optional) The integration runtime reference.
- `annotations` - (Optional) A list of tags to annotate the linked service.
- `parameters` - (Optional) A map of parameters.
- `additional_properties` - (Optional) Additional custom properties.
- `credential_name` - (Optional) The name of a User-assigned Managed Identity for authentication.
- `key_vault_connection_string` - (Optional) Use an existing Key Vault to store the Azure SQL Database connection string.
  - `linked_service_name` - (Required) The name of the Key Vault Linked Service.
  - `secret_name` - (Required) The secret storing the SQL Server connection string.
- `key_vault_password` - (Optional) Use an existing Key Vault to store the Azure SQL Database password.
  - `linked_service_name` - (Required) The name of the Key Vault Linked Service.
  - `secret_name` - (Required) The secret storing the SQL Server password.
DESCRIPTION
}

variable "linked_service_data_lake_storage_gen2" {
  type = map(object({
    name                     = string
    data_factory_id          = optional(string)
    description              = optional(string, null)
    integration_runtime_name = optional(string, null)
    annotations              = optional(list(string), null)
    parameters               = optional(map(string), null)
    additional_properties    = optional(map(string), null)
    url                      = string
    storage_account_key      = optional(string, null)
    use_managed_identity     = optional(bool, null)
    service_principal_id     = optional(string, null)
    service_principal_key    = optional(string, null)
    tenant                   = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of Azure Data Factory Linked Services for Data Lake Storage Gen2, where each key represents a unique configuration.
Each object in the map consists of the following properties:

- `name` - (Required) The unique name of the linked service.
- `data_factory_id` - (Required) The ID of the Data Factory where the linked service is associated.
- `description` - (Optional) A description of the linked service.
- `integration_runtime_name` - (Optional) The integration runtime reference.
- `annotations` - (Optional) A list of tags to annotate the linked service.
- `parameters` - (Optional) A map of parameters.
- `additional_properties` - (Optional) Additional custom properties.
- `url` - (Required) The endpoint for the Azure Data Lake Storage Gen2 service.

### Authentication Options (Only one can be set):
- `storage_account_key` - (Optional) The Storage Account Key used for authentication. **Incompatible with** `service_principal_id`, `service_principal_key`, `tenant`, and `use_managed_identity`.
- `use_managed_identity` - (Optional) Whether to use the Data Factory's managed identity for authentication. **Incompatible with** `service_principal_id`, `service_principal_key`, `tenant`, and `storage_account_key`.
- `service_principal_id` - (Optional) The service principal ID used for authentication. **Incompatible with** `storage_account_key` and `use_managed_identity`.
- `service_principal_key` - (Optional) The service principal key used for authentication. **Required if** `service_principal_id` **is set.**
- `tenant` - (Optional) The tenant ID where the service principal exists. **Required if** `service_principal_id` **is set.**
DESCRIPTION
}

variable "linked_service_databricks" {
  type = map(object({
    adb_domain                 = string
    data_factory_id            = optional(string)
    name                       = string
    additional_properties      = optional(map(string), null)
    annotations                = optional(list(string), null)
    description                = optional(string, null)
    integration_runtime_name   = optional(string, null)
    parameters                 = optional(map(string), null)
    access_token               = optional(string, null)
    msi_work_space_resource_id = optional(string, null)
    key_vault_password = optional(object({
      linked_service_name = string
      secret_name         = string
    }), null)
    existing_cluster_id = optional(string, null)
    instance_pool = optional(object({
      instance_pool_id      = string
      cluster_version       = string
      min_number_of_workers = optional(number, 1)
      max_number_of_workers = optional(number, null)
    }), null)
    new_cluster_config = optional(object({
      cluster_version             = string
      node_type                   = string
      driver_node_type            = optional(string, null)
      max_number_of_workers       = optional(number, null)
      min_number_of_workers       = optional(number, 1)
      spark_config                = optional(map(string), null)
      spark_environment_variables = optional(map(string), null)
      custom_tags                 = optional(map(string), null)
      init_scripts                = optional(list(string), null)
      log_destination             = optional(string, null)
    }), null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of Azure Data Factory Linked Services for Databricks, where each key represents a unique configuration.
Each object in the map consists of the following properties:

- `adb_domain` - (Required) The domain URL of the Databricks instance.
- `data_factory_id` - (Required) The ID of the Data Factory where the linked service is associated.
- `name` - (Required) The unique name of the linked service.
- `additional_properties` - (Optional) Additional custom properties.
- `annotations` - (Optional) A list of tags to annotate the linked service.
- `description` - (Optional) A description of the linked service.
- `integration_runtime_name` - (Optional) The integration runtime reference.
- `parameters` - (Optional) A map of parameters.

### Authentication Options (Only one can be set):
- `access_token` - (Optional) Authenticate to Databricks via an access token.
- `key_vault_password` - (Optional) Authenticate via Azure Key Vault. 
  - `linked_service_name` - (Required) Name of the Key Vault Linked Service.
  - `secret_name` - (Required) The secret storing the access token.
- `msi_work_space_resource_id` - (Optional) Authenticate via managed service identity.

### Cluster Integration Options (Only one can be set):
- `existing_cluster_id` - (Optional) The ID of an existing cluster.
- `instance_pool` - (Optional) Use an instance pool. This requires a nested `instance_pool` block.
  - `instance_pool_id` - (Required) The identifier of the instance pool.
  - `cluster_version` - (Required) The Spark version.
  - `min_number_of_workers` - (Optional) Minimum worker nodes (default: 1).
  - `max_number_of_workers` - (Optional) Maximum worker nodes.
- `new_cluster_config` - (Optional) Create a new cluster.
  - `cluster_version` - (Required) Spark version.
  - `node_type` - (Required) Node type.
  - `driver_node_type` - (Optional) Driver node type.
  - `max_number_of_workers` - (Optional) Max workers.
  - `min_number_of_workers` - (Optional) Min workers (default: 1).
  - `spark_config` - (Optional) Key-value pairs for Spark configuration.
  - `spark_environment_variables` - (Optional) Spark environment variables.
  - `custom_tags` - (Optional) Tags for the cluster.
  - `init_scripts` - (Optional) Initialization scripts.
  - `log_destination` - (Optional) Log storage location.
DESCRIPTION
}

variable "linked_service_key_vault" {
  type = map(object({
    name                     = string
    data_factory_id          = optional(string)
    key_vault_id             = string
    description              = optional(string, null)
    integration_runtime_name = optional(string, null)
    annotations              = optional(list(string), null)
    parameters               = optional(map(string), null)
    additional_properties    = optional(map(string), null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of Azure Data Factory Linked Services for Azure Key Vault, where each key represents a unique configuration.
Each object in the map consists of the following properties:

- `name` - (Required) The unique name of the linked service.
- `data_factory_id` - (Required) The ID of the Data Factory where the linked service is associated.
- `key_vault_id` - (Required) The ID of the Azure Key Vault resource.
- `description` - (Optional) A description of the linked service.
- `integration_runtime_name` - (Optional) The integration runtime reference.
- `annotations` - (Optional) A list of tags to annotate the linked service.
- `parameters` - (Optional) A map of parameters.
- `additional_properties` - (Optional) Additional custom properties.
DESCRIPTION
}

variable "lock" {
  type = object({
    kind = string
    name = optional(string, null)
  })
  default     = null
  description = <<DESCRIPTION
Controls the Resource Lock configuration for this resource. The following properties can be specified:

- `kind` - (Required) The type of lock. Possible values are `\"CanNotDelete\"` and `\"ReadOnly\"`.
- `name` - (Optional) The name of the lock. If not specified, a name will be generated based on the `kind` value. Changing this forces the creation of a new resource.

Example Input:
```hcl
lock = {
  kind = "CanNotDelete"
  name = "Delete"
}
```
DESCRIPTION

  validation {
    condition     = var.lock != null ? contains(["CanNotDelete", "ReadOnly"], var.lock.kind) : true
    error_message = "Lock kind must be either `\"CanNotDelete\"` or `\"ReadOnly\"`."
  }
}

variable "managed_identities" {
  type = object({
    system_assigned            = optional(bool, false)
    user_assigned_resource_ids = optional(set(string), [])
  })
  default     = {}
  description = <<DESCRIPTION
Controls the Managed Identity configuration on this resource. The following properties can be specified:

- `system_assigned` - (Optional) Specifies if the System Assigned Managed Identity should be enabled.
- `user_assigned_resource_ids` - (Optional) Specifies a list of User Assigned Managed Identity resource IDs to be assigned to this resource.

Example Input:

```hcl
managed_identities = {
  system_assigned = true
}
```
DESCRIPTION
  nullable    = false
}

variable "managed_virtual_network_enabled" {
  type        = bool
  default     = false
  description = "Is Managed Virtual Network enabled?"
}

variable "private_endpoints" {
  type = map(object({
    name = optional(string, null)
    role_assignments = optional(map(object({
      role_definition_id_or_name             = string
      principal_id                           = string
      description                            = optional(string, null)
      skip_service_principal_aad_check       = optional(bool, false)
      condition                              = optional(string, null)
      condition_version                      = optional(string, null)
      delegated_managed_identity_resource_id = optional(string, null)
      principal_type                         = optional(string, null)
    })), {})
    lock = optional(object({
      kind = string
      name = optional(string, null)
    }), null)
    tags                                    = optional(map(string), null)
    subnet_resource_id                      = string
    private_dns_zone_group_name             = optional(string, "default")
    private_dns_zone_resource_ids           = optional(set(string), [])
    application_security_group_associations = optional(map(string), {})
    private_service_connection_name         = optional(string, null)
    network_interface_name                  = optional(string, null)
    location                                = optional(string, null)
    resource_group_name                     = optional(string, null)
    ip_configurations = optional(map(object({
      name               = string
      private_ip_address = string
    })), {})
  }))
  default     = {}
  description = <<DESCRIPTION
A map of private endpoints to create on this resource. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `name` - (Optional) The name of the private endpoint. One will be generated if not set.
- `role_assignments` - (Optional) A map of role assignments to create on the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time. See `var.role_assignments` for more information.
- `lock` - (Optional) The lock level to apply to the private endpoint. Default is `None`. Possible values are `None`, `CanNotDelete`, and `ReadOnly`.
- `tags` - (Optional) A mapping of tags to assign to the private endpoint.
- `subnet_resource_id` - The resource ID of the subnet to deploy the private endpoint in.
- `private_dns_zone_group_name` - (Optional) The name of the private DNS zone group. One will be generated if not set.
- `private_dns_zone_resource_ids` - (Optional) A set of resource IDs of private DNS zones to associate with the private endpoint. If not set, no zone groups will be created and the private endpoint will not be associated with any private DNS zones. DNS records must be managed external to this module.
- `application_security_group_resource_ids` - (Optional) A map of resource IDs of application security groups to associate with the private endpoint. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
- `private_service_connection_name` - (Optional) The name of the private service connection. One will be generated if not set.
- `network_interface_name` - (Optional) The name of the network interface. One will be generated if not set.
- `location` - (Optional) The Azure location where the resources will be deployed. Defaults to the location of the resource group.
- `resource_group_name` - (Optional) The resource group where the resources will be deployed. Defaults to the resource group of this resource.
- `ip_configurations` - (Optional) A map of IP configurations to create on the private endpoint. If not specified the platform will create one. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.
  - `name` - The name of the IP configuration.
  - `private_ip_address` - The private IP address of the IP configuration.

Example Input:

```hcl
private_endpoints = {
  endpoint1 = {
    subnet_resource_id            = azurerm_subnet.endpoint.id
    private_dns_zone_group_name   = "private-dns-zone-group"
    private_dns_zone_resource_ids = [azurerm_private_dns_zone.this.id]
  }
}
```
DESCRIPTION
  nullable    = false
}

variable "private_endpoints_manage_dns_zone_group" {
  type        = bool
  default     = true
  description = "Default to true. Whether to manage private DNS zone groups with this module. If set to false, you must manage private DNS zone groups externally, e.g. using Azure Policy."
  nullable    = false
}

variable "public_network_enabled" {
  type        = bool
  default     = true
  description = "Is the Data Factory visible to the public network?"
}

variable "purview_id" {
  type        = string
  default     = null
  description = "Specifies the ID of the purview account resource associated with the Data Factory."
}

variable "role_assignments" {
  type = map(object({
    role_definition_id_or_name             = string
    principal_id                           = string
    description                            = optional(string, null)
    skip_service_principal_aad_check       = optional(bool, false)
    condition                              = optional(string, null)
    condition_version                      = optional(string, null)
    delegated_managed_identity_resource_id = optional(string, null)
    principal_type                         = optional(string, null)
  }))
  default     = {}
  description = <<DESCRIPTION
A map of role assignments to create on the <RESOURCE>. The map key is deliberately arbitrary to avoid issues where map keys maybe unknown at plan time.

- `role_definition_id_or_name` - The ID or name of the role definition to assign to the principal.
- `principal_id` - The ID of the principal to assign the role to.
- `description` - (Optional) The description of the role assignment.
- `skip_service_principal_aad_check` - (Optional) If set to true, skips the Azure Active Directory check for the service principal in the tenant. Defaults to false.
- `condition` - (Optional) The condition which will be used to scope the role assignment.
- `condition_version` - (Optional) The version of the condition syntax. Leave as `null` if you are not using a condition, if you are then valid values are '2.0'.
- `delegated_managed_identity_resource_id` - (Optional) The delegated Azure Resource Id which contains a Managed Identity. Changing this forces a new resource to be created. This field is only used in cross-tenant scenario.
- `principal_type` - (Optional) The type of the `principal_id`. Possible values are `User`, `Group` and `ServicePrincipal`. It is necessary to explicitly set this attribute when creating role assignments if the principal creating the assignment is constrained by ABAC rules that filters on the PrincipalType attribute.

> Note: only set `skip_service_principal_aad_check` to true if you are assigning a role to a service principal.

Example Input:

```hcl
role_assignments = {
  deployment_user_contributor = {
    role_definition_id_or_name = "Contributor"
    principal_id               = data.azurerm_client_config.current.client_id
  }
}
```
DESCRIPTION
  nullable    = false
}

variable "tags" {
  type        = map(string)
  default     = null
  description = "A mapping of tags to assign to the resource."
}

variable "vsts_configuration" {
  type = object({
    account_name       = string
    branch_name        = string
    project_name       = string
    repository_name    = string
    root_folder        = string
    tenant_id          = string
    publishing_enabled = optional(bool, true)
  })
  default     = null
  description = <<DESCRIPTION
Defines the VSTS configuration for the Data Factory.
- account_name: Specifies the VSTS account name.
- branch_name: Specifies the branch of the repository to get code from.
- project_name: Specifies the name of the VSTS project.
- repository_name: Specifies the name of the git repository.
- root_folder: Specifies the root folder within the repository. Set to / for the top level.
- tenant_id: Specifies the Tenant ID associated with the VSTS account.
- publishing_enabled: Is automated publishing enabled? Defaults to true.
DESCRIPTION
}

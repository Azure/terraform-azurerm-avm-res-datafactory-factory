# Tests the self-hosted integration runtime with RBAC authorization and a
# user-assigned managed identity credential.
variables {
  name                = "df-test-ir"
  resource_group_name = "rg-test-ir"
  location            = "eastus"
  enable_telemetry    = false

  credential_user_managed_identity = {
    example = {
      name        = "credential-test-identity"
      identity_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-host/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test-identity"
      annotations = ["test"]
      description = "Test credential"
    }
  }

  integration_runtime_self_hosted = {
    example = {
      name        = "ir-test"
      description = "test description"
      rbac_authorization = {
        resource_id     = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-host/providers/Microsoft.DataFactory/factories/df-host/integrationRuntimes/ir-host"
        credential_name = "credential-test-identity"
      }
    }
  }

  managed_identities = {
    system_assigned = false
    user_assigned_resource_ids = [
      "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-host/providers/Microsoft.ManagedIdentity/userAssignedIdentities/test-identity"
    ]
  }
}

run "plan_integration_runtime_self_hosted" {
  command = plan
}

# Tests diagnostic settings configuration.
variables {
  name                = "df-test-diag"
  resource_group_name = "rg-test-diag"
  location            = "eastus"
  enable_telemetry    = false

  diagnostic_settings = {
    to_la = {
      name                  = "to-la"
      workspace_resource_id = "/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-test/providers/Microsoft.OperationalInsights/workspaces/la-test"
    }
  }
}

run "plan_diagnostic_settings" {
  command = plan
}

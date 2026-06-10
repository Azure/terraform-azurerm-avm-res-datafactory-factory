# Tests the basic module configuration — minimal required variables only.
variables {
  name                = "df-test-basic"
  resource_group_name = "rg-test-basic"
  location            = "eastus"
  enable_telemetry    = false
}

run "plan_basic" {
  command = plan
}

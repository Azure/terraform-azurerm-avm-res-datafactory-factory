// Keep the legacy default for unnamed endpoints in different resource groups.
// Only generate keyed names when two or more unnamed endpoints share a group.
// The hash distinguishes keys that truncate or normalize identically.
locals {
  unnamed_private_endpoint_counts_by_group = {
    for key, endpoint in var.private_endpoints :
    key => length([
      for other in values(var.private_endpoints) : true
      if other.name == null && (
        lower(coalesce(other.resource_group_name, var.resource_group_name)) ==
        lower(coalesce(endpoint.resource_group_name, var.resource_group_name))
      )
    ])
  }

  private_endpoint_names = {
    for key, endpoint in var.private_endpoints :
    key => endpoint.name != null ? endpoint.name : (
      local.unnamed_private_endpoint_counts_by_group[key] <= 1
      ? "pe-${var.name}"
      : "pep-${substr(var.name, 0, 36)}-${substr(lower(replace(key, "/[^0-9A-Za-z_-]/", "-")), 0, 10)}-${substr(sha1(key), 0, 12)}"
    )
  }
}

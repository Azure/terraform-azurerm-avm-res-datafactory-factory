package Azure_Proactive_Resiliency_Library_v2

import rego.v1

exception contains rules if {
  rules = [
    "mission_critical_virtual_machine_should_use_premium_or_ultra_disks",
    "public_ip_use_standard_sku_and_zone_redundant_ip"
  ]
}
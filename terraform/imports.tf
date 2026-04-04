# Import pre-existing resources created during manual bootstrap.
# These import blocks are safe to leave in place — once a resource is
# in state, Terraform ignores the import block on subsequent runs.

import {
  to = azurerm_resource_group.main
  id = "/subscriptions/${var.subscription_id}/resourceGroups/RG-SENTINEL-SOC-PROD-CAE-001"
}

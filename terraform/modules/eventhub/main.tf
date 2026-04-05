# ─── Event Hub Namespace ───────────────────────────────────────────────────────

resource "azurerm_eventhub_namespace" "main" {
  name                          = "evhns-soc-prod-cae-001"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku                           = "Standard"
  capacity                      = 1
  public_network_access_enabled = false
  local_authentication_enabled  = false

  tags = merge(var.common_tags, {
    description = "Event Hub Namespace for SOC incident and alert streaming"
  })
}

# ─── Event Hubs ────────────────────────────────────────────────────────────────

resource "azurerm_eventhub" "incidents" {
  name                = "incidents"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = var.resource_group_name
  partition_count     = var.partition_count
  message_retention   = 1
}

resource "azurerm_eventhub" "alerts" {
  name                = "alerts"
  namespace_name      = azurerm_eventhub_namespace.main.name
  resource_group_name = var.resource_group_name
  partition_count     = var.partition_count
  message_retention   = 1
}

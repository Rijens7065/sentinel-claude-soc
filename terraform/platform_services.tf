# ─── Sentinel Module ──────────────────────────────────────────────────────────

module "sentinel" {
  source = "./modules/sentinel"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  common_tags         = local.common_tags
}

# ─── Event Hub Module ─────────────────────────────────────────────────────────

module "eventhub" {
  source = "./modules/eventhub"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  common_tags         = local.common_tags
}

# ─── Application Insights ─────────────────────────────────────────────────────

resource "azurerm_application_insights" "main" {
  name                = "appi-sentinel-soc-prod-cae-001"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  workspace_id        = module.sentinel.law_id
  application_type    = "web"

  tags = merge(local.common_tags, {
    description = "Application Insights for SOC platform observability"
  })
}

# ─── Additional Private DNS Zones (needed for AMPLS) ──────────────────────────

locals {
  ampls_dns_zones = {
    oms      = "privatelink.oms.opinsights.azure.com"
    ods      = "privatelink.ods.opinsights.azure.com"
    agentsvc = "privatelink.agentsvc.azure-automation.net"
  }
}

resource "azurerm_private_dns_zone" "ampls" {
  for_each            = local.ampls_dns_zones
  name                = each.value
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(local.common_tags, {
    description = "Private DNS zone for ${each.key} (AMPLS)"
  })
}

resource "azurerm_private_dns_zone_virtual_network_link" "ampls" {
  for_each              = local.ampls_dns_zones
  name                  = "link-${each.key}"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.ampls[each.key].name
  virtual_network_id    = module.networking.vnet_id
  registration_enabled  = false

  tags = local.common_tags
}

# ─── Azure Monitor Private Link Scope ─────────────────────────────────────────

resource "azurerm_monitor_private_link_scope" "main" {
  name                = "AMPLS-SOC-PROD-CAE-001"
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(local.common_tags, {
    description = "Azure Monitor Private Link Scope for LAW and App Insights"
  })
}

resource "azurerm_monitor_private_link_scoped_service" "law" {
  name                = "ampls-law"
  resource_group_name = azurerm_resource_group.main.name
  scope_name          = azurerm_monitor_private_link_scope.main.name
  linked_resource_id  = module.sentinel.law_id
}

resource "azurerm_monitor_private_link_scoped_service" "appi" {
  name                = "ampls-appi"
  resource_group_name = azurerm_resource_group.main.name
  scope_name          = azurerm_monitor_private_link_scope.main.name
  linked_resource_id  = azurerm_application_insights.main.id
}

# ─── Private Endpoint — LAW (via AMPLS) ───────────────────────────────────────

resource "azurerm_private_endpoint" "monitor" {
  name                = "PE-LAW-PROD-CAE-001"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.networking.subnet_private_endpoints_id

  private_service_connection {
    name                           = "psc-monitor"
    private_connection_resource_id = azurerm_monitor_private_link_scope.main.id
    subresource_names              = ["azuremonitor"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name = "dns-monitor"
    private_dns_zone_ids = [
      module.networking.private_dns_zone_ids["monitor"],
      module.networking.private_dns_zone_ids["blob"],
      azurerm_private_dns_zone.ampls["oms"].id,
      azurerm_private_dns_zone.ampls["ods"].id,
      azurerm_private_dns_zone.ampls["agentsvc"].id,
    ]
  }

  tags = merge(local.common_tags, {
    description = "Private endpoint for Log Analytics and App Insights via AMPLS"
  })
}

# ─── Private Endpoint — Event Hub ─────────────────────────────────────────────

resource "azurerm_private_endpoint" "eventhub" {
  name                = "PE-EVHNS-PROD-CAE-001"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = module.networking.subnet_private_endpoints_id

  private_service_connection {
    name                           = "psc-eventhub"
    private_connection_resource_id = module.eventhub.namespace_id
    subresource_names              = ["namespace"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "dns-eventhub"
    private_dns_zone_ids = [module.networking.private_dns_zone_ids["servicebus"]]
  }

  tags = merge(local.common_tags, {
    description = "Private endpoint for Event Hub Namespace"
  })
}

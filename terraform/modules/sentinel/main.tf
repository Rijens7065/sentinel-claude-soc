# ─── Log Analytics Workspace ───────────────────────────────────────────────────

resource "azurerm_log_analytics_workspace" "main" {
  name                = "law-sentinel-soc-prod-cae-001"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "PerGB2018"
  retention_in_days   = var.law_retention_days

  tags = merge(var.common_tags, {
    description = "Log Analytics Workspace for Sentinel SOC platform"
  })
}

# ─── Microsoft Sentinel ───────────────────────────────────────────────────────

resource "azurerm_sentinel_log_analytics_workspace_onboarding" "main" {
  workspace_id = azurerm_log_analytics_workspace.main.id
}

# ─── Sentinel Data Connectors ─────────────────────────────────────────────────

resource "azurerm_sentinel_data_connector_microsoft_threat_protection" "defender_xdr" {
  name                       = "MicrosoftThreatProtection"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.main.workspace_id
}

resource "azurerm_sentinel_data_connector_azure_security_center" "security_incidents" {
  name                       = "AzureSecurityCenter"
  log_analytics_workspace_id = azurerm_sentinel_log_analytics_workspace_onboarding.main.workspace_id
}

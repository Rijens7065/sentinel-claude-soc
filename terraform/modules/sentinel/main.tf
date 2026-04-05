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
# Defender XDR and Azure Security Center connectors are managed natively
# by Azure (auto-enabled on Sentinel onboarding). They are NOT managed by
# Terraform due to internal kind mismatches in the azurerm provider.
# Enable/configure these connectors in the Azure Portal:
#   Sentinel → Configuration → Data connectors

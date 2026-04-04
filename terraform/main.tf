locals {
  region_short = "cae"
  name_suffix  = "PROD-CAE-001"

  common_tags = {
    managed_by  = "terraform"
    project     = var.project
    environment = var.environment
    repository  = "github.com/Rijens7065/sentinel-claude-soc"
  }
}

# ─── Resource Group ────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "main" {
  name     = "RG-SENTINEL-SOC-${local.name_suffix}"
  location = var.location

  tags = merge(local.common_tags, {
    description = "Primary resource group for the sentinel-claude-soc SOC platform"
  })
}

# ─── Key Vault ─────────────────────────────────────────────────────────────────

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = "KV-SENTINEL-SOC-${local.name_suffix}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tenant_id           = var.tenant_id
  sku_name            = "standard"

  # Security hardening
  enable_rbac_authorization     = true
  purge_protection_enabled      = true
  soft_delete_retention_days    = 90
  public_network_access_enabled = false

  network_acls {
    bypass         = "AzureServices"
    default_action = "Deny"
  }

  tags = merge(local.common_tags, {
    description = "Central Key Vault for all SOC platform secrets and certificates"
  })
}

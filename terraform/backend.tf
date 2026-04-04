terraform {
  backend "azurerm" {
    resource_group_name  = "RG-SENTINEL-SOC-PROD-CAE-001"
    storage_account_name = "stsocprodcae001"
    container_name       = "terraform-state"
    key                  = "sentinel-claude-soc.tfstate"
    use_oidc             = true
  }
}

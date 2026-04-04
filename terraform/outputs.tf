output "resource_group_name" {
  description = "Name of the primary resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_location" {
  description = "Location of the primary resource group"
  value       = azurerm_resource_group.main.location
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.main.name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = azurerm_key_vault.main.vault_uri
}

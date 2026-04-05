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

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = module.networking.vnet_id
}

output "subnet_functions_id" {
  description = "ID of the Functions subnet"
  value       = module.networking.subnet_functions_id
}

output "subnet_private_endpoints_id" {
  description = "ID of the Private Endpoints subnet"
  value       = module.networking.subnet_private_endpoints_id
}

output "vnet_id" {
  description = "ID of the Virtual Network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the Virtual Network"
  value       = azurerm_virtual_network.main.name
}

output "subnet_functions_id" {
  description = "ID of the Functions subnet"
  value       = azurerm_subnet.functions.id
}

output "subnet_private_endpoints_id" {
  description = "ID of the Private Endpoints subnet"
  value       = azurerm_subnet.private_endpoints.id
}

output "subnet_reserved_id" {
  description = "ID of the Reserved subnet"
  value       = azurerm_subnet.reserved.id
}

output "private_dns_zone_ids" {
  description = "Map of private DNS zone names to their IDs"
  value       = { for k, zone in azurerm_private_dns_zone.zones : k => zone.id }
}

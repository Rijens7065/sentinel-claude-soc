output "namespace_id" {
  description = "ID of the Event Hub Namespace"
  value       = azurerm_eventhub_namespace.main.id
}

output "namespace_name" {
  description = "Name of the Event Hub Namespace"
  value       = azurerm_eventhub_namespace.main.name
}

output "incidents_hub_name" {
  description = "Name of the incidents Event Hub"
  value       = azurerm_eventhub.incidents.name
}

output "alerts_hub_name" {
  description = "Name of the alerts Event Hub"
  value       = azurerm_eventhub.alerts.name
}

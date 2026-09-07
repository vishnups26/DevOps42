# Outputs surfaced after `terraform apply` - useful for pipeline logs,
# downstream automation, or just sanity-checking what was deployed.

output "resource_group_name" {
  description = "Name of the resource group that was created."
  value       = azurerm_resource_group.rg.name
}

output "servicebus_namespace_name" {
  description = "Name of the Service Bus namespace that was created."
  value       = azurerm_servicebus_namespace.sbus.name
}

output "servicebus_namespace_id" {
  description = "Resource ID of the Service Bus namespace."
  value       = azurerm_servicebus_namespace.sbus.id
}

output "servicebus_queue_names" {
  description = "Names of the Service Bus queues that were created."
  value = [
    azurerm_servicebus_queue.queue01.name,
    azurerm_servicebus_queue.queue02.name,
  ]
}

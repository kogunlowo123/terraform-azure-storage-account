output "id" {
  description = "The ID of the storage account."
  value       = azurerm_storage_account.this.id
}

output "name" {
  description = "The name of the storage account."
  value       = azurerm_storage_account.this.name
}

output "primary_location" {
  description = "The primary location of the storage account."
  value       = azurerm_storage_account.this.primary_location
}

output "secondary_location" {
  description = "The secondary location of the storage account."
  value       = azurerm_storage_account.this.secondary_location
}

output "primary_blob_endpoint" {
  description = "The primary blob endpoint."
  value       = azurerm_storage_account.this.primary_blob_endpoint
}

output "primary_file_endpoint" {
  description = "The primary file endpoint."
  value       = azurerm_storage_account.this.primary_file_endpoint
}

output "primary_queue_endpoint" {
  description = "The primary queue endpoint."
  value       = azurerm_storage_account.this.primary_queue_endpoint
}

output "primary_table_endpoint" {
  description = "The primary table endpoint."
  value       = azurerm_storage_account.this.primary_table_endpoint
}

output "primary_web_endpoint" {
  description = "The primary web endpoint (for static website)."
  value       = azurerm_storage_account.this.primary_web_endpoint
}

output "primary_access_key" {
  description = "The primary access key."
  value       = azurerm_storage_account.this.primary_access_key
  sensitive   = true
}

output "secondary_access_key" {
  description = "The secondary access key."
  value       = azurerm_storage_account.this.secondary_access_key
  sensitive   = true
}

output "primary_connection_string" {
  description = "The primary connection string."
  value       = azurerm_storage_account.this.primary_connection_string
  sensitive   = true
}

output "secondary_connection_string" {
  description = "The secondary connection string."
  value       = azurerm_storage_account.this.secondary_connection_string
  sensitive   = true
}

output "primary_blob_connection_string" {
  description = "The primary blob connection string."
  value       = azurerm_storage_account.this.primary_blob_connection_string
  sensitive   = true
}

output "identity" {
  description = "The identity block of the storage account."
  value       = try(azurerm_storage_account.this.identity[0], null)
}

output "container_ids" {
  description = "Map of container names to their resource manager IDs."
  value       = { for k, v in azurerm_storage_container.this : k => v.resource_manager_id }
}

output "file_share_ids" {
  description = "Map of file share names to their resource manager IDs."
  value       = { for k, v in azurerm_storage_share.this : k => v.resource_manager_id }
}

output "queue_ids" {
  description = "Map of queue names to their IDs."
  value       = { for k, v in azurerm_storage_queue.this : k => v.id }
}

output "table_ids" {
  description = "Map of table names to their IDs."
  value       = { for k, v in azurerm_storage_table.this : k => v.id }
}

output "private_endpoint_ids" {
  description = "Map of private endpoint names to their IDs."
  value       = { for k, v in azurerm_private_endpoint.this : k => v.id }
}

output "private_endpoint_ip_addresses" {
  description = "Map of private endpoint names to their private IP addresses."
  value       = { for k, v in azurerm_private_endpoint.this : k => v.private_service_connection[0].private_ip_address }
}

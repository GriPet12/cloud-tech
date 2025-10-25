output "resource_group_name" {
  description = "The name of the deployed resource group."
  value       = azurerm_resource_group.rg.name
}

output "storage_account_name" {
  description = "The globally unique name of the deployed storage account."
  value       = azurerm_storage_account.sa.name
}

output "storage_account_primary_blob_endpoint" {
  description = "The primary blob endpoint URL for the storage account."
  value       = azurerm_storage_account.sa.primary_blob_endpoint
}

output "vnet_name" {
  description = "The name of the deployed virtual network."
  value       = azurerm_virtual_network.vnet.name
}
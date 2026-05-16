output "resource_group_name" {
  description = "The name of the resource group where the virtual network is created"
  value       = azurerm_resource_group.main_rg.name
  }

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = azurerm_virtual_network.vnet.id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = azurerm_subnet.private_subnet.id
}

output "aks_subnet_id" {
  description = "The ID of the AKS subnet"
  value       = azurerm_subnet.aks_subnet.id
}

output "bastion_subnet_id" {
  description = "The ID of the Bastion subnet"
  value       = azurerm_subnet.bastion_subnet.id
}
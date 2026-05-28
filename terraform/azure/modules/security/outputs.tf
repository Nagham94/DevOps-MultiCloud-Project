output "nsg_id" {
  description = "The ID of the Network Security Group"
  value       = azurerm_network_security_group.main_nsg.id
}

output "bastion_host" {
  description = "The DNS name of the Azure Bastion host"
  value       = azurerm_bastion_host.bastion_host.dns_name
}

output "acr_login_server" {
  description = "The login server of the Azure Container Registry"
  value       = azurerm_container_registry.main.login_server
}

output "acr_id" {
  description = "The ID of the Azure Container Registry"
  value       = azurerm_container_registry.main.id
}

output "nsg_aks_id" {
  description = "The ID of the NSG associated with the AKS subnet"
  value       = azurerm_network_security_group.aks.id
}
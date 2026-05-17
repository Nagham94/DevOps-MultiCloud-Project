output "nsg_id"{
    description = "The ID of the Network Security Group"
    value       = azurerm_network_security_group.main_nsg.id
}

output "bastion_host" {
    description = "The DNS name of the Azure Bastion host"
    value       = azurerm_bastion_host.bastion_host.dns_name
}
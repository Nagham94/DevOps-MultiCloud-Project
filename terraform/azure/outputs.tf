output "resource_group_name" {
  description = "The name of the resource group where the virtual network is created"
  value       = module.networking.resource_group_name
}

output "vnet_id" {
  description = "The ID of the virtual network"
  value       = module.networking.vnet_id
}

output "private_subnet_id" {
  description = "The ID of the private subnet"
  value       = module.networking.private_subnet_id
}

output "vm_private_ip" {
  description = "The private IP address of the VM"
  value       = module.compute.vm_private_ip
}

output "ssh_private_key" {
  description = "The private SSH key for the VM"
  value       = module.compute.ssh_private_key
  sensitive   = true
}

output "acr_login_server" {
  description = "The login server of the Azure Container Registry"
  value       = module.security.acr_login_server
}

output "bastion_host" {
  description = "The DNS name of the Azure Bastion host"
  value       = module.security.bastion_host
}

output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = module.compute.aks_cluster_name
}
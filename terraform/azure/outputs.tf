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
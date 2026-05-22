output "vm_private_ip" {
  description = "The private IP address of the VM"
  value       = azurerm_network_interface.nic-jenkins.private_ip_address
}

/*
output "storage_account_id" {
  description = "The ID of the storage account used for the VM's OS disk"
  value       = azurerm_storage_account.main.id
}
*/

output "ssh_private_key" {
  description = "The private SSH key for the VM"
  value       = tls_private_key.key.private_key_pem
  sensitive   = true
}
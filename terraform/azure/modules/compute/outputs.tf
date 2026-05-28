output "vm_private_ip" {
  description = "The private IP address of the VM"
  value       = azurerm_network_interface.nic-jenkins.private_ip_address
}

output "ssh_private_key" {
  description = "The private SSH key for the VM"
  value       = tls_private_key.key.private_key_pem
  sensitive   = true
}

output "vm_name" {
  description = "The name of the VM"
  value       = azurerm_linux_virtual_machine.jenkins.name
}
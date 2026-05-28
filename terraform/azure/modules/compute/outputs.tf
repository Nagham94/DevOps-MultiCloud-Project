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

output "log_analytics_workspace_id" {
  description = "The ID of the Log Analytics Workspace for monitoring"
  value       = azurerm_log_analytics_workspace.main.id
}

output "aks_cluster_name" {
  description = "The name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "aks_cluster_id" {
  description = "The ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}
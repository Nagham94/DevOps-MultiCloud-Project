# SSH key
resource "tls_private_key" "key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

# nic for jenkins VM: no public ips
resource "azurerm_network_interface" "nic-jenkins" {
  name                = "nic-jenkins-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.private_subnet_id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_association" {
  network_interface_id      = azurerm_network_interface.nic-jenkins.id
  network_security_group_id = var.nsg_id
}

# jenkins VM in private subnet
resource "azurerm_linux_virtual_machine" "jenkins" {
  name                  = "vm-jenkins-${var.environment}"
  location              = var.location
  resource_group_name   = var.resource_group_name
  size                  = var.vm_size
  admin_username        = var.admin_username
  network_interface_ids = [azurerm_network_interface.nic-jenkins.id]
  tags                  = var.tags

  admin_ssh_key {
    username   = var.admin_username
    public_key = tls_private_key.key.public_key_openssh
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 64
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  disable_password_authentication = true
}

# for monitoring and logs of AKS and VMs
resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-analytics-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  # sku is PerGB2018 for pay-as-you-go. It allows you to pay based on the amount of data ingested and stored
  sku                 = "PerGB2018"
  # save data for 30 days
  retention_in_days   = 30
  tags                = var.tags
}

data "azurerm_client_config" "current" {}

# AKS cluster
resource "azurerm_kubernetes_cluster" "main" {
  name                    = "aks-${var.environment}-cluster"
  location                = var.location
  resource_group_name     = var.resource_group_name
  dns_prefix              = "aks-${var.environment}"
  private_cluster_enabled = true
  tags                    = var.tags

  # System node pool
  default_node_pool {
    name                = "system"
    node_count          = 1
    vm_size             = "Standard_D2s_v3"
    vnet_subnet_id      = var.aks_subnet_id
    os_disk_size_gb     = 50
    auto_scaling_enabled = true
    min_count            = 1
    max_count            = 3

    node_labels = {
      "nodepool-type" = "system"
      "environment"   = var.environment
    }
  }

  # Azure given identity for AKS to manage resources securely without needing to store credentials in code
  identity {
    type = "SystemAssigned"
  }

  # Azure CNI makes sure that pods get IP addresses from the same VNet as the cluster
  network_profile {
    network_plugin    = "azure"
    load_balancer_sku = "standard"
    service_cidr      = "172.16.0.0/16"
    dns_service_ip    = "172.16.0.10"
  }

  # Azure AD RBAC for secure access control to the cluster resources based on Azure AD identities and roles
  azure_active_directory_role_based_access_control {
    azure_rbac_enabled = true
    tenant_id          = data.azurerm_client_config.current.tenant_id
  }

  # Connect to Log Analytics for monitoring
  oms_agent {
    log_analytics_workspace_id = azurerm_log_analytics_workspace.main.id
  }
}

# ignored due to free tier limits
/*
# Separate from system pool to run the application workloads.
# to scale and manage the app nodes independently from the system nodes, which are critical for cluster operations. 
# We can also apply different node labels and taints if needed in the future.
resource "azurerm_kubernetes_cluster_node_pool" "app" {
  name                  = "app"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_D2s_v3"
  vnet_subnet_id        = var.aks_subnet_id
  os_disk_size_gb       = 50
  auto_scaling_enabled = true
  min_count             = 1
  max_count             = 5
  tags                  = var.tags

  node_labels = {
    "nodepool-type" = "app"
    "environment"   = var.environment
  }
}
*/

# AKS uses Managed Identity to pull images from ACR
# No username or password needed
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = var.acr_id
  depends_on           = [azurerm_kubernetes_cluster.main]
}

resource "local_file" "ssh_private_key" {
  content         = tls_private_key.key.private_key_pem
  filename        = pathexpand("~/.ssh/jenkins_vm.pem")
  file_permission = "0400"

  depends_on = [azurerm_linux_virtual_machine.jenkins]
}





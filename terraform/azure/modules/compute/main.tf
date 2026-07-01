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

# Separate app node pool for running portfolio deployments
# (System node pool is auto-created in default_node_pool above)
resource "azurerm_kubernetes_cluster_node_pool" "app" {
  name                  = "app"
  kubernetes_cluster_id = azurerm_kubernetes_cluster.main.id
  vm_size               = "Standard_D2s_v3"
  vnet_subnet_id        = var.aks_subnet_id
  os_disk_size_gb       = 50
  auto_scaling_enabled  = true
  min_count             = 1
  max_count             = 3
  tags                  = var.tags

  node_labels = {
    "nodepool-type" = "app"
    "environment"   = var.environment
  }
}

# AKS uses Managed Identity to pull images from ACR
# No username or password needed
resource "azurerm_role_assignment" "aks_acr_pull" {
  principal_id         = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
  role_definition_name = "AcrPull"
  scope                = var.acr_id
  depends_on           = [azurerm_kubernetes_cluster.main]
}

# ── Storage Account for Jenkins (persistent data via Azure Files) ──
# Azure Files Share for Jenkins home directory (DR equivalent to AWS EFS)
resource "azurerm_storage_account" "jenkins" {
  name                     = "st${replace(var.environment, "-", "")}jenkins"
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  https_traffic_only_enabled = true
  tags                     = var.tags
}

# Network rule for storage account — only allow VNet
resource "azurerm_storage_account_network_rules" "jenkins" {
  storage_account_id = azurerm_storage_account.jenkins.id
  default_action     = "Deny"
  virtual_network_subnet_ids = [var.private_subnet_id, var.aks_subnet_id]
  bypass                     = ["AzureServices"]
}

# Jenkins file share
resource "azurerm_storage_share" "jenkins" {
  name               = "jenkins-home"
  storage_account_id = azurerm_storage_account.jenkins.id
  quota              = 100
}

# Private endpoint for storage account (Jenkins VM access)
resource "azurerm_private_endpoint" "jenkins_storage" {
  name                = "pe-storage-jenkins-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.private_subnet_id
  tags                = var.tags

  private_service_connection {
    name                           = "psc-storage-jenkins-${var.environment}"
    private_connection_resource_id = azurerm_storage_account.jenkins.id
    subresource_names              = ["file"]
    is_manual_connection           = false
  }
}

# SSH Key Storage
resource "local_file" "ssh_private_key" {
  content             = tls_private_key.key.private_key_pem
  filename            = pathexpand("~/.ssh/jenkins_vm_azure.pem")
  file_permission     = "0400"

  depends_on = [azurerm_linux_virtual_machine.jenkins]
}





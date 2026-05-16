# main resource group and virtual network with subnets for private resources, AKS and Azure Bastion
resource "azurerm_resource_group" "main_rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-${var.environment}"
  location            = azurerm_resource_group.main_rg.location
  resource_group_name = azurerm_resource_group.main_rg.name
  address_space       = [var.vnet_address_space]
  tags = var.tags
}

resource "azurerm_subnet" "private_subnet" {
  name                 = "snet-${var.environment}-private"
  resource_group_name  = azurerm_resource_group.main_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space, 8, 1)]
}

resource "azurerm_subnet" "aks_subnet" {
  name                 = "snet-${var.environment}-aks"
  resource_group_name  = azurerm_resource_group.main_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = [cidrsubnet(var.vnet_address_space, 8, 2)]
}

resource "azurerm_subnet" "bastion_subnet" {
  # Azure Bastion requires a specific subnet name
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main_rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  # bastion require /26 or larger subnet
  address_prefixes     = [cidrsubnet(var.vnet_address_space, 10, 255)]
}
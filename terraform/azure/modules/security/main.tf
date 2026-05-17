resource "azurerm_network_security_group" "main_nsg" {
  name                = "nsg-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
  # security rule to allow inbound HTTPS traffic from the virtual network only
  security_rule {
    name                       = "AllowHTTPSInbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  # security rule to allow inbound HTTP traffic from the virtual network only
  security_rule {
    name                       = "AllowHTTPInbound"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "*"
  }
  # security rule to deny all other inbound traffic - no public access
  security_rule {
    name                       = "DenyAllInbound"
    priority                   = 4096
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_association" {
  subnet_id                 = var.private_subnet_id
  network_security_group_id = azurerm_network_security_group.main_nsg.id
}

resource "azurerm_public_ip" "bastion_public_ip" {
  name                = "bastion-pip-${var.environment}"
  resource_group_name = var.resource_group_name
  location            = var.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = var.tags
}

resource "azurerm_bastion_host" "bastion_host" {
  name                = "bastion-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  ip_configuration {
    name                 = "configuration"
    subnet_id            = var.bastion_subnet_id
    public_ip_address_id = azurerm_public_ip.bastion_public_ip.id
  }
}

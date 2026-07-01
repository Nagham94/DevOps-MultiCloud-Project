module "networking" {
  source              = "./modules/networking"
  resource_group_name = var.resource_group_name
  location            = var.location
  vnet_address_space  = var.vnet_address_space
  tags                = var.tags
  environment         = var.environment
}

module "security" {
  source              = "./modules/security"
  resource_group_name = module.networking.resource_group_name
  location            = var.location
  tags                = var.tags
  environment         = var.environment
  private_subnet_id      = module.networking.private_subnet_id
  bastion_subnet_id      = module.networking.bastion_subnet_id
  bastion_subnet_prefix  = module.networking.bastion_subnet_prefix
  aks_subnet_id          = module.networking.aks_subnet_id
  vnet_id                = module.networking.vnet_id
  endpoints_subnet_id    = module.networking.endpoints_subnet_id
}

module "compute" {
  source              = "./modules/compute"
  resource_group_name = module.networking.resource_group_name
  location            = var.location
  tags                = var.tags
  environment         = var.environment
  private_subnet_id   = module.networking.private_subnet_id
  nsg_id              = module.security.nsg_id
  admin_username      = var.admin_username
  vm_size             = var.vm_size
  aks_subnet_id       = module.networking.aks_subnet_id
  acr_id              = module.security.acr_id
}

# Traffic Manager Profile
resource "azurerm_traffic_manager_profile" "main" {
  name                   = "tm-portfolio-global"
  resource_group_name    = module.networking.resource_group_name
  traffic_routing_method = "Priority"

  dns_config {
    relative_name = "portfolio-nagham"
    ttl           = 60
  }

  monitor_config {
    protocol                     = "HTTP"
    port                         = 80
    path                         = "/health"
    interval_in_seconds          = 30
    timeout_in_seconds           = 10
    tolerated_number_of_failures = 2
  }

  tags = var.tags
}

# AWS EKS endpoint — Priority 1 (primary)
resource "azurerm_traffic_manager_external_endpoint" "eks" {
  name       = "endpoint-eks-aws"
  profile_id = azurerm_traffic_manager_profile.main.id
  target     = var.eks_alb_dns
  priority   = 1
  weight     = 100
}

# Azure AKS endpoint — Priority 2 (disaster recovery)
resource "azurerm_traffic_manager_azure_endpoint" "aks" {
  name               = "endpoint-aks-azure"
  profile_id         = azurerm_traffic_manager_profile.main.id
  target_resource_id = var.aks_ingress_ip
  priority           = 2
  weight             = 100
}



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
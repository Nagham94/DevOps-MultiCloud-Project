module "networking" {
  source = "./modules/networking" 
  resource_group_name = var.resource_group_name
  location            = var.location
  vnet_address_space  = var.vnet_address_space
  tags                = var.tags
  environment         = var.environment
}

module "security" {
  source = "./modules/security"
  resource_group_name = module.networking.resource_group_name
  location            = var.location
  tags                = var.tags
  environment         = var.environment
  private_subnet_id   = module.networking.private_subnet_id
  bastion_subnet_id   = module.networking.bastion_subnet_id
}
module "networking" {
  source = "./modules/networking" 
  resource_group_name = var.resource_group_name
  location            = var.location
  vnet_address_space  = var.vnet_address_space
  tags                = var.tags
  environment         = var.environment
}
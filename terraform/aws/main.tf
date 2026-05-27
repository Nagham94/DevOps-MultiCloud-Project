module "networking" {
  source      = "./modules/networking"
  environment = var.environment
  vpc_cidr    = var.vpc_cidr
  tags        = var.tags
  aws_region  = var.aws_region
}

module "compute" {
  source             = "./modules/compute"
  environment        = var.environment
  tags               = var.tags
  vpc_id             = module.networking.vpc_id
  private_subnet_ids = module.networking.private_subnet_ids
  security_group_id  = module.networking.security_group_id
  instance_type      = var.instance_type
}
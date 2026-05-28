environment         = "prod"
resource_group_name = "rg-prod-westeurope"
location            = "West Europe"
vnet_address_space  = "10.0.0.0/16"
vm_size             = "Standard_B2s_v2"
admin_username      = "azureuser"
tags = {
  environment = "prod"
  project     = "devops-multicloud"
  owner       = "nagham"
}
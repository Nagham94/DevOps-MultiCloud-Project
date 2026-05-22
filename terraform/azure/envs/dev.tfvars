environment         = "dev"
resource_group_name = "rg-dev-westeurope"
location            = "West Europe"
vnet_address_space  = "10.1.0.0/16"
vm_size             = "Standard_B2s_v2"
admin_username      = "azureuser"
tags = {
  environment  = "dev"
  project      = "devops-multicloud"
  owner        = "nagham"
  }
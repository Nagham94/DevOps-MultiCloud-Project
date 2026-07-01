variable "environment" {
  description = "Environment name: dev or prod"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the main resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
  default     = "West Europe"
}

variable "vnet_address_space" {
  description = "The address space for the virtual network"
  type        = string
  default     = "10.0.0.0/16"
}

variable "tags" {
  description = "A map of tags to apply to the resources"
  type        = map(string)
  default     = {}
}

variable "admin_username" {
  description = "Admin username for the VM"
  type        = string
  default     = "azureuser"
}

variable "vm_size" {
  description = "The size of the VM"
  type        = string
  default     = "Standard_B2s"
}

variable "eks_alb_dns" {
  description = "The DNS name of the ALB for EKS"
  type        = string
  default     = ""
}

variable "aks_ingress_ip" {
  description = "The public IP address of the AKS ingress controller"
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "The name of the resource group where the VM will be created"
  type        = string
}

variable "location" {
  description = "The location where the VM will be created"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the VM"
  type        = map(string)
}

variable "environment" {
  description = "The environment for which the VM is being created"
  type        = string
}

variable "private_subnet_id" {
  description = "The ID of the private subnet to which the VM will be connected"
  type        = string
}

variable "nsg_id" {
  description = "The ID of the Network Security Group to associate with the VM's network interface"
  type        = string
}

variable "admin_username" {
  description = "The admin username for the VM"
  type        = string
}

variable "vm_size" {
  description = "The size of the VM"
  type        = string
}

variable "aks_subnet_id" {
  description = "The ID of the subnet to which the AKS cluster will be connected"
  type        = string
}

variable "acr_id" {
  description = "The ID of the Azure Container Registry to allow AKS to pull images from"
  type        = string
}
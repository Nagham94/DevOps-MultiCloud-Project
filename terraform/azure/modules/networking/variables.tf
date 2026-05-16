variable "resource_group_name" {
  description = "The name of the main resource group"
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created"
  type        = string
}

variable "vnet_address_space" {
  description = "The address space for the virtual network"
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the resources"
  type        = map(string)
}

variable "environment" {
  description = "The environment for which the resources are being created"
  type        = string
}
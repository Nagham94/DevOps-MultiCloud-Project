variable "environment" {
  description = "The environment for which the NSG is being created"
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group where the NSG is located"
  type        = string
}

variable "location" {
  description = "The location of the NSG"
  type        = string
}

variable "tags" {
  description = "A map of tags to assign to the NSG"
  type        = map(string)
}

variable "private_subnet_id" {
  description = "The ID of the private subnet to associate with the NSG"
  type        = string
}

variable "bastion_subnet_id" {
  description = "The ID of the bastion subnet to associate with the NSG"
  type        = string
}
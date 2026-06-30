variable "environment" {
  description = "The environment for which the infrastructure is being provisioned"
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy resources into"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for the EFS mount target"
  type        = list(string)
}

variable "eks_nodes_security_group_id" {
  description = "Security group ID for EKS worker nodes / EC2 instances that will mount EFS"
  type        = string
}

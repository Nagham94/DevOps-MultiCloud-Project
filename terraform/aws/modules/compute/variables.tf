variable "environment" {
  description = "The environment for which the infrastructure is being provisioned"
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy EC2 instances in"
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type to use for the Jenkins/App server"
  type        = string
  default     = "t3.medium"
}

variable "private_subnet_ids" {
  description = "A list of private subnet IDs to launch EC2 instances in"
  type        = list(string)
}

/*
variable "security_group_id" {
  description = "The ID of the security group to attach to the EC2 instance"
  type        = string
}

*/

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.30"
}

variable "manage_eks_access" {
  description = "Whether to create EKS Access entries and policy associations via the EKS Access API. Set true only when cluster auth mode supports API access."
  type        = bool
  default     = false
}

variable "terraform_admin_principal_arn" {
  description = "Principal ARN (IAM user or role) to grant cluster admin via EKS Access. Leave empty to skip."
  type        = string
  default     = ""
}

variable "eks_nodes_security_group_id" {
  description = "The ID of the security group to attach to the EKS worker nodes"
  type        = string
}

variable "eks_cluster_security_group_id" {
  description = "The ID of the security group to attach to the EKS cluster for communication with worker nodes"
  type        = string
}
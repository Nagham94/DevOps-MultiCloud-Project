variable "aws_region" {
  description = "The AWS region to deploy resources in"
  type        = string
}

variable "environment" {
  description = "The environment for which the infrastructure is being provisioned"
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to all resources"
  type        = map(string)
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  type        = string
}

variable "instance_type" {
  description = "The EC2 instance type to use for the Jenkins/App server"
  type        = string
  default     = "t3.micro"
}
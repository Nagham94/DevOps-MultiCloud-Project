output "vpc_id" {
  description = "The ID of the VPC"
  value       = module.networking.vpc_id
}

output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = module.compute.instance_id
}

output "instance_private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = module.compute.instance_private_ip
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = module.compute.ecr_repository_url
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = module.compute.eks_cluster_name
}

output "eks_cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = module.compute.eks_cluster_endpoint
}

output "terraform_caller_arn" {
  value       = module.compute.terraform_caller_arn
  description = "The IAM ARN used to access EKS"
}

output "efs_file_system_id" {
  description = "The ID of the Jenkins EFS filesystem"
  value       = module.preserved_efs.efs_file_system_id
}

output "efs_dns_name" {
  description = "The DNS name of the Jenkins EFS for mounting in EC2"
  value       = module.preserved_efs.efs_dns_name
}

output "efs_mount_target_id" {
  description = "The ID of the EFS mount target in the Jenkins subnet"
  value       = module.preserved_efs.efs_mount_target_id
}

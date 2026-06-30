output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "The IDs of the public subnets"
  value       = aws_subnet.public[*].id
}
output "private_subnet_ids" {
  description = "The IDs of the private subnets"
  value       = aws_subnet.private[*].id
}

/*
output "security_group_id" {
  description = "The ID of the main security group"
  value       = aws_security_group.main.id
}

*/

output "eks_cluster_security_group_id" {
  description = "The ID of the security group for EKS cluster communication"
  value       = aws_security_group.eks_cluster.id
}

output "eks_nodes_security_group_id" {
  description = "The ID of the security group for EKS worker nodes"
  value       = aws_security_group.eks_nodes.id
}


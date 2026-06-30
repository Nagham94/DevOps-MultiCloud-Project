output "instance_id" {
  description = "The ID of the EC2 instance"
  value       = aws_instance.main.id
}

output "instance_private_ip" {
  description = "The private IP address of the EC2 instance"
  value       = aws_instance.main.private_ip
}

output "ecr_repository_url" {
  description = "The URL of the ECR repository"
  value       = aws_ecr_repository.portfolio.repository_url
}

output "eks_cluster_name" {
  description = "The name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "eks_cluster_endpoint" {
  description = "The endpoint of the EKS cluster"
  value       = aws_eks_cluster.main.endpoint
}

output "terraform_caller_arn" {
  value       = data.aws_iam_session_context.current.issuer_arn
  description = "The IAM ARN used to access EKS"
}

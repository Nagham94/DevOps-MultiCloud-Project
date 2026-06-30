output "efs_file_system_id" {
  description = "The ID of the Jenkins EFS filesystem"
  value       = aws_efs_file_system.jenkins.id
}

output "efs_dns_name" {
  description = "The DNS name of the Jenkins EFS filesystem for mounting"
  value       = aws_efs_file_system.jenkins.dns_name
}

output "efs_mount_target_id" {
  description = "The ID of the Jenkins EFS mount target"
  value       = aws_efs_mount_target.jenkins.id
}

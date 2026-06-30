resource "aws_efs_file_system" "jenkins" {
  creation_token   = "jenkins-home-${var.environment}"
  performance_mode = "generalPurpose"
  throughput_mode  = "bursting"
  encrypted        = true
  tags = merge(var.tags, {
    Name = "jenkins-home-${var.environment}"
  })
}

resource "aws_security_group" "efs" {
  name        = "efs-jenkins-${var.environment}"
  description = "Allow NFS access to Jenkins EFS from EC2"
  vpc_id      = var.vpc_id
  tags = merge(var.tags, {
    Name = "efs-jenkins-${var.environment}"
  })

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [var.eks_nodes_security_group_id]
    description     = "NFS from Jenkins EC2"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
}

resource "aws_efs_mount_target" "jenkins" {
  file_system_id  = aws_efs_file_system.jenkins.id
  subnet_id       = var.private_subnet_ids[0]
  security_groups = [aws_security_group.efs.id]
  depends_on      = [aws_efs_file_system.jenkins]
}

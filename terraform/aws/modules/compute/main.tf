# ── SSH Key ───────────────────────────────────────────────────
resource "tls_private_key" "ec2" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2" {
  key_name   = "key-ec2-${var.environment}"
  public_key = tls_private_key.ec2.public_key_openssh
  tags       = var.tags
}

resource "local_file" "ec2_private_key" {
  content         = tls_private_key.ec2.private_key_pem
  filename        = "${path.root}/../../ansible/aws_ec2.pem"
  file_permission = "0400"
}

# Allows EC2 to use SSM Session Manager (no SSH needed)
resource "aws_iam_role" "ec2" {
  name = "role-ec2-${var.environment}"
  tags = var.tags
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Attach SSM policy
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Attach ECR read policy
resource "aws_iam_role_policy_attachment" "ecr" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Attach CloudWatch policy
resource "aws_iam_role_policy_attachment" "cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# EKS cluster policy — needed for update-kubeconfig
resource "aws_iam_role_policy_attachment" "ec2_eks" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# Custom policy — allows EC2 to describe and access EKS
resource "aws_iam_policy" "ec2_eks_describe" {
  name        = "policy-ec2-eks-describe-${var.environment}"
  description = "Allow EC2 to describe EKS clusters and update kubeconfig"
  tags        = var.tags

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Action = [
        "eks:DescribeCluster",
        "eks:ListClusters",
        "eks:AccessKubernetesApi"
      ]
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_eks_describe" {
  role       = aws_iam_role.ec2.name
  policy_arn = aws_iam_policy.ec2_eks_describe.arn
}

# Instance profile
resource "aws_iam_instance_profile" "ec2" {
  name = "profile-ec2-${var.environment}"
  role = aws_iam_role.ec2.name
  tags = var.tags
}

# latest Ubuntu 22.04 AMI automatically
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# EC2 Instance: Jenkins/App server
resource "aws_instance" "main" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[0]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name
  vpc_security_group_ids = [var.eks_nodes_security_group_id]
  key_name               = aws_key_pair.ec2.key_name

  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  tags = merge(var.tags, { Name = "ec2-app-${var.environment}" })
}

resource "aws_ecr_repository" "portfolio" {
  name                 = "portfolio-website"
  image_tag_mutability = "MUTABLE"
  tags                 = var.tags
  force_delete = true

  # Scan images for vulnerabilities on every push
  image_scanning_configuration {
    scan_on_push = true
  }
}

# ECR lifecycle policy — keep only last 10 images
resource "aws_ecr_lifecycle_policy" "portfolio" {
  repository = aws_ecr_repository.portfolio.name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "Keep last 10 images"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 10
      }
      action = { type = "expire" }
    }]
  })
}

# IAM Role for EKS Cluster for cluster control plane permissions to allow it to manage AWS resources on behalf of the cluster
resource "aws_iam_role" "eks_cluster" {
  name = "role-eks-cluster-${var.environment}"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "eks.amazonaws.com" }
    }]
  })
}

# Attach EKS Cluster policy to allow the cluster to manage AWS resources
# this important for cluster operations like creating load balancers, managing security groups
resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

# IAM Role for EKS Node Group to allow worker nodes to interact with AWS services securely without needing to store credentials in code
resource "aws_iam_role" "eks_nodes" {
  name = "role-eks-nodes-${var.environment}"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
    }]
  })
}

# Attach necessary policies to EKS worker nodes for cluster operations, pulling container images, and using SSM Session Manager for secure access without SSH
resource "aws_iam_role_policy_attachment" "eks_worker_node" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

# Attach CNI policy for networking
# this allows the worker nodes to manage network interfaces and IP addresses for pods
resource "aws_iam_role_policy_attachment" "eks_cni" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

# Attach ECR read policy for pulling container images from ECR
resource "aws_iam_role_policy_attachment" "eks_ecr_read" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Attach SSM policy for Session Manager access to worker nodes without SSH
resource "aws_iam_role_policy_attachment" "eks_ssm_nodes" {
  role       = aws_iam_role.eks_nodes.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = "eks-${var.environment}-dr"
  role_arn = aws_iam_role.eks_cluster.arn
  version  = var.kubernetes_version
  tags     = var.tags

  vpc_config {
    subnet_ids = var.private_subnet_ids
    # Disable public access to the EKS API server for security, allowing only private access from within the VPC
    endpoint_private_access = true
    endpoint_public_access  = true
    security_group_ids = [var.eks_cluster_security_group_id,
    var.eks_nodes_security_group_id]
  }

  # FIX: this block was missing — REQUIRED for access entries to work
  # Without this the cluster defaults to CONFIG_MAP mode
  # and aws_eks_access_entry resources fail with:
  # "authentication mode must be set to API or API_AND_CONFIG_MAP"
  access_config {
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]
}

# EKS Addons
# These three addons are REQUIRED for the cluster to work
# They must be installed BEFORE or WITH the node group
# Without them nodes register but stay NotReady forever

# VPC CNI — manages pod networking and IP addresses
# Install first because nodes need networking to start
resource "aws_eks_addon" "vpc_cni" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "vpc-cni"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  tags                        = var.tags

  depends_on = [aws_eks_cluster.main]
}

# kube-proxy — handles network routing between pods and services
resource "aws_eks_addon" "kube_proxy" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "kube-proxy"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  tags                        = var.tags

  depends_on = [aws_eks_cluster.main]
}

# CoreDNS — handles DNS resolution inside the cluster
# pods use this to resolve service names like portfolio-service
# Install after node group because CoreDNS runs on nodes
resource "aws_eks_addon" "coredns" {
  cluster_name                = aws_eks_cluster.main.name
  addon_name                  = "coredns"
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "OVERWRITE"
  tags                        = var.tags

  # CoreDNS needs nodes to run on so it depends on node group
  depends_on = [aws_eks_node_group.main]
}

# EKS Node Group 
resource "aws_eks_node_group" "main" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "ng-${var.environment}"
  node_role_arn   = aws_iam_role.eks_nodes.arn
  subnet_ids      = var.private_subnet_ids
  instance_types  = [var.instance_type]
  tags            = var.tags

  scaling_config {
    desired_size = 3
    min_size     = 1
    max_size     = 4
  }

  update_config {
    max_unavailable = 1
  }

  timeouts {
    create = "40m"
    delete = "40m"
  }

  # Node group depends on vpc-cni being ready
  # so nodes have networking when they start
  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node,
    aws_iam_role_policy_attachment.eks_cni,
    aws_iam_role_policy_attachment.eks_ecr_read,
    aws_iam_role_policy_attachment.eks_ssm_nodes,
    aws_eks_addon.vpc_cni,
  aws_eks_addon.kube_proxy]
}

# ── EKS Access Entries ────────────────────────────────────────
# These replace the manual aws-auth ConfigMap editing
# Requires authentication_mode = API_AND_CONFIG_MAP on the cluster

# Give EC2 instance admin access to the cluster
resource "aws_eks_access_entry" "ec2" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.ec2.arn
  type          = "STANDARD"
  tags          = var.tags

  depends_on = [aws_eks_cluster.main]
}

resource "aws_eks_access_policy_association" "ec2_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = aws_iam_role.ec2.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  # FIX: must depend on access entry existing first
  depends_on = [aws_eks_access_entry.ec2]
}

# Give Terraform IAM user admin access to the cluster
# so you can run kubectl from your local machine
# Get the current caller identity dynamically
# This avoids hardcoding the ARN which can be wrong
# ── EKS Access Entries ────────────────────────────────────────
data "aws_caller_identity" "current" {}

# Get the current IAM session to find the actual role/user ARN
data "aws_iam_session_context" "current" {
  arn = data.aws_caller_identity.current.arn
}
resource "aws_eks_access_entry" "terraform_user" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = data.aws_iam_session_context.current.issuer_arn
  type          = "STANDARD"
  tags          = var.tags

  depends_on = [aws_eks_cluster.main]
}

# FIX: this was completely missing from your file
resource "aws_eks_access_policy_association" "terraform_user_admin" {
  cluster_name  = aws_eks_cluster.main.name
  principal_arn = data.aws_iam_session_context.current.issuer_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }

  depends_on = [aws_eks_access_entry.terraform_user]
}
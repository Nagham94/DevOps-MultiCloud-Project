data "aws_availability_zones" "available" {
  state = "available"
}

# vpc 
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = merge(var.tags, { Name = "vpc-${var.environment}" })
}

# Subnets
resource "aws_subnet" "private" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 1)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false
  tags = merge(var.tags, {
    Name = "snet-private-${var.environment}-${count.index}"
    # The following tags are important for EKS to recognize these subnets as private and suitable for worker nodes
    "kubernetes.io/role/internal-elb"                 = "1"
    "kubernetes.io/cluster/eks-${var.environment}-dr" = "shared"
  })
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 8, count.index + 101)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = merge(var.tags, {
    Name = "snet-public-${var.environment}-${count.index}"
    # The following tags are important for EKS to recognize these subnets as public and suitable for load balancers
    "kubernetes.io/role/elb"                          = "1"
    "kubernetes.io/cluster/eks-${var.environment}-dr" = "shared"
  })
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags   = merge(var.tags, { Name = "igw-${var.environment}" })
}

resource "aws_eip" "nat" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.main]
  tags       = merge(var.tags, { Name = "eip-nat-${var.environment}" })
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.main]
  tags          = merge(var.tags, { Name = "nat-${var.environment}" })
}

# Route tables and associations
# Public route table for public subnets with direct internet access
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  tags = merge(var.tags, {
    Name = "rt-public-${var.environment}"
  })

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Private route table with NAT gateway for outbound internet access from private subnets
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = merge(var.tags, { Name = "rt-private-${var.environment}" })
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

# Security Group for EKS Control Plane
# Used by the EKS cluster itself
resource "aws_security_group" "eks_cluster" {
  name        = "eks-cluster-${var.environment}"
  description = "EKS cluster control plane security group"
  vpc_id      = aws_vpc.main.id
  tags = merge(var.tags, {
    Name = "eks-cluster-${var.environment}"
  })

  # Allow HTTPS from within VPC
  # Nodes use this to talk to the API server
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS from VPC - nodes to API server"
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
}

# Security Group for EKS Worker Nodes
# Used by the EC2 instances that are EKS nodes
resource "aws_security_group" "eks_nodes" {
  name        = "eks-nodes-${var.environment}"
  description = "EKS worker nodes security group"
  vpc_id      = aws_vpc.main.id
  tags = merge(var.tags, {
    Name = "eks-nodes-${var.environment}"

    # EKS uses this tag to find the node security group
    "kubernetes.io/cluster/eks-${var.environment}-dr" = "owned"
  })

  # Allow nodes to talk to each other
  # Required for pod-to-pod communication across nodes
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
    description = "Allow node to node communication"
  }

  # Allow control plane to reach nodes
  # Required for kubectl exec, logs, port-forward
  ingress {
    from_port   = 1025
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow control plane to reach nodes"
  }

  # Allow HTTPS from control plane to nodes
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Allow HTTPS from control plane"
  }

  # Allow app port from within VPC
  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Node.js app port from VPC"
  }

  # Allow HTTP and HTTPS for ingress controller
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTP for ingress"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS for ingress"
  }

  # Allow all outbound
  # Nodes need this for pulling images, AWS API calls
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
}


# VPC Gateway Endpoint for S3 (avoid NAT for S3 traffic)
# for EKS to pull container images from S3 without going through the NAT gateway, which saves costs and improves performance
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
  tags              = merge(var.tags, { Name = "vpce-s3-${var.environment}" })
}

# Interface endpoints for ECR to allow image pulls without NAT
resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.eks_cluster.id]
  private_dns_enabled = true
  tags                = merge(var.tags, { Name = "vpce-ecr-api-${var.environment}" })
}

# Interface endpoint for ECR Docker to allow image pulls without NAT
resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.eks_cluster.id]
  private_dns_enabled = true
  tags                = merge(var.tags, { Name = "vpce-ecr-dkr-${var.environment}" })
}

# SSM — for Session Manager access to EC2 and EKS nodes
resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.eks_cluster.id]
  private_dns_enabled = true
  tags = merge(var.tags, {
    Name = "vpce-ssm-${var.environment}"
  })
}

# SSM Messages — REQUIRED for SSM Session Manager to work
# This endpoint allows the SSM agent on the nodes to communicate with the SSM service for session management, command execution, and other SSM features without needing internet access.
resource "aws_vpc_endpoint" "ssm_messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssmmessages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.eks_cluster.id]
  private_dns_enabled = true
  tags = merge(var.tags, {
    Name = "vpce-ssmmessages-${var.environment}"
  })
}

# EC2 Messages — REQUIRED for SSM Session Manager to work
# This endpoint allows the SSM agent on the nodes to communicate with the EC2 Messages service, which is used for sending messages to and from EC2 instances as part of SSM Session Manager functionality.
resource "aws_vpc_endpoint" "ec2_messages" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ec2messages"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.eks_cluster.id]
  private_dns_enabled = true
  tags = merge(var.tags, {
    Name = "vpce-ec2messages-${var.environment}"
  })
}

# ── EKS API Server VPC Endpoint ───────────────────────────────
# CRITICAL: Without this, nodes in private subnets cannot
# reach the EKS API server to register themselves.
# This is why your node group was stuck for 25+ minutes.
resource "aws_vpc_endpoint" "eks" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.eks"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.eks_cluster.id]
  private_dns_enabled = true
  tags = merge(var.tags, {
    Name = "vpce-eks-${var.environment}"
  })
}

/*
resource "aws_security_group" "main" {
  name        = "security-group-${var.environment}"
  description = "Main security group: deny all, allow specific"
  vpc_id      = aws_vpc.main.id
  tags        = merge(var.tags, { Name = "sg-${var.environment}" })

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTPS from VPC only"
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "HTTP from VPC only"
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]
    description = "Node.js app port from VPC only"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = aws_vpc.main.id
  service_name        = "com.amazonaws.${var.aws_region}.ssm"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = aws_subnet.private[*].id
  security_group_ids  = [aws_security_group.main.id]
  private_dns_enabled = true
  tags                = merge(var.tags, { Name = "vpce-ssm-${var.environment}" })
}

data "aws_availability_zones" "available" {
  state = "available"
}

*/
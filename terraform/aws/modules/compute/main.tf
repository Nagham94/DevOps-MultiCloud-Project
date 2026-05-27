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
  vpc_security_group_ids = [var.security_group_id]

  associate_public_ip_address = false

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 30
    delete_on_termination = true
    encrypted             = true
  }

  user_data = <<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y \
      docker.io \
      awscli \
      amazon-ssm-agent

    # Start and enable Docker
    systemctl enable docker
    systemctl start docker

    # Start SSM agent — this is what allows Session Manager access
    systemctl enable amazon-ssm-agent
    systemctl start amazon-ssm-agent
  EOF


  tags = merge(var.tags, { Name = "ec2-app-${var.environment}" })
}

resource "aws_ecr_repository" "portfolio" {
  name                 = "portfolio-website"
  image_tag_mutability = "MUTABLE"
  tags                 = var.tags

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
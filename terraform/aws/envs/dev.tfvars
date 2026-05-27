environment   = "dev"
aws_region    = "us-east-1"
vpc_cidr      = "10.0.0.0/16"
instance_type = "t3.micro"

tags = {
  environment = "dev"
  project     = "devops-multicloud"
  owner       = "nagham"
  managed-by  = "terraform"
}
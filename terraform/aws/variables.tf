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
  default     = "t3.medium"
}

variable "kubernetes_version" {
  description = "Default Kubernetes version for EKS clusters"
  type        = string
  default     = "1.30"
}

#export AWS_PROFILE=multi-cloud
#echo $AWS_PROFILE
#aws eks delete-access-entry   --cluster-name eks-prod-dr   --principal-arn arn:aws:iam::254652353999:user/Nagham
#INSTANCE_ID=$(terraform output -raw instance_id)
#echo $INSTANCE_ID
#aws ssm start-session   --target $INSTANCE_ID   --document-name AWS-StartPortForwardingSession   --parameters '{"portNumber":["22"],"localPortNumber":["2222"]}'   --region eu-north-1
#ANSIBLE_CONFIG=aws.cfg ansible-playbook   -i ansible/inventory/aws.ini   ansible/playbooks/setup-ec2.yml   -e "eks_cluster_name=eks-prod-dr eks_region=eu-north-1"   --ask-vault-pass   -v
#aws ssm start-session   --target $INSTANCE_ID   --document-name AWS-StartPortForwardingSession   --parameters '{"portNumber":["8080"],"localPortNumber":["8080"]}'


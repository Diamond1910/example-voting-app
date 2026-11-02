#terraform vpc_config
terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1" 
}

# 1. Look up existing AWS account default VPC components
data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# 2. IAM Control Plane Permissions setup
resource "aws_iam_role" "cluster" {
  name = "voting-app-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "://amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster.name
}

# 3. AWS Managed Kubernetes Engine Creation
resource "aws_eks_cluster" "main" {
  name     = "voting-app-cluster"
  role_arn = aws_iam_role.cluster.arn

  vpc_config {
    subnet_ids = data.aws_subnets.default.ids
  }

  depends_on = [aws_iam_role_policy_attachment_cluster_policy]
}

# 4. IAM Identity Management for Compute Nodes
resource "aws_iam_role" "node_group" {
  name = "voting-app-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "://amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "node_worker" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_cni" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group.name
}

resource "aws_iam_role_policy_attachment" "node_ecr" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group.name
}

# 5. Compute Scaling Capacity (Worker Node Groups)
resource "aws_eks_node_group" "nodes" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "voting-app-workers"
  node_role_arn   = aws_iam_role.node_group.arn
  subnet_ids      = data.aws_subnets.default.ids

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_iam_role_policy_attachment_node_worker,
    aws_iam_role_policy_attachment_node_cni,
    aws_iam_role_policy_attachment_node_ecr,
  ]
}

output "cluster_endpoint" { value = aws_eks_cluster.main.endpoint }
output "cluster_name"     { value = aws_eks_cluster.main.name }

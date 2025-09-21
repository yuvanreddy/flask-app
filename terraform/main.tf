# Define the AWS provider
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# -----------------------------------------------------------------------------
# VPC and Networking
# -----------------------------------------------------------------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "${var.project_name}-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  count             = 2
  cidr_block        = "10.0.${count.index + 1}.0/24"
  vpc_id            = aws_vpc.main.id
  map_public_ip_on_launch = true
  tags = {
    Name = "${var.project_name}-public-subnet-${count.index}"
  }
}

# -----------------------------------------------------------------------------
# EKS Cluster (Note: This is a basic example. A full production setup requires more configuration.)
# -----------------------------------------------------------------------------
# resource "aws_eks_cluster" "main" {
#   name     = "${var.project_name}-cluster"
#   role_arn = aws_iam_role.eks_master.arn

#   vpc_config {
#     subnet_ids = [aws_subnet.public_subnet[0].id, aws_subnet.public_subnet[1].id]
#   }
#   tags = {
#     Name = "${var.project_name}-cluster"
#   }
# }

# Note: The above EKS resource is commented out as it requires IAM roles and more complex setup.
# In a real-world scenario, you would uncomment this and add the necessary IAM resources.
# This file serves as a starting point to demonstrate the structure.
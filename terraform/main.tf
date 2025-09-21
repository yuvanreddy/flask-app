############################################################
# Main infrastructure stack (VPC + EKS)
# Region: var.aws_region (default us-east-1)
# Cluster name: var.cluster_name (e.g., my-flask)
# Requires: providers and versions in versions.tf/providers.tf
############################################################

########################
# Caller identity (for EKS aws-auth access)
########################
data "aws_caller_identity" "current" {}

########################
# VPC (2 AZs, 2x public, 2x private)
########################
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = "${var.project_name}-vpc"
  cidr = var.vpc_cidr

  azs             = var.azs
  public_subnets  = var.public_subnet_cidrs
  private_subnets = var.private_subnet_cidrs

  enable_nat_gateway = true
  single_nat_gateway = true

  # Tag subnets for Kubernetes load balancers at creation time
  public_subnet_tags = {
    "kubernetes.io/role/elb"                         = "1"
    "kubernetes.io/cluster/${var.cluster_name}"     = "shared"
  }

  private_subnet_tags = {
    "kubernetes.io/role/internal-elb"                = "1"
    "kubernetes.io/cluster/${var.cluster_name}"     = "shared"
  }

  tags = {
    Project = var.project_name
  }
}

########################
# EKS Cluster + Managed Node Group
########################
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.8" # EKS module v20 for AWS provider v5

  cluster_name    = var.cluster_name
  cluster_version = var.kubernetes_version

  vpc_id                   = module.vpc.vpc_id
  subnet_ids               = module.vpc.private_subnets
  control_plane_subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  enable_irsa = true
  enable_cluster_creator_admin_permissions = true

  eks_managed_node_groups = {
    default = {
      min_size     = 2
      max_size     = 4
      desired_size = 2

      instance_types = [var.node_instance_type]
      capacity_type  = "ON_DEMAND"
      subnets        = module.vpc.private_subnets
    }
  }

  tags = {
    Project = var.project_name
  }
}

########################
# Subnet tags handled in VPC module (see public_subnet_tags/private_subnet_tags)
########################

########################
# Outputs
########################
output "vpc_id" {
  value = module.vpc.vpc_id
}

output "public_subnets" {
  value = module.vpc.public_subnets
}

output "private_subnets" {
  value = module.vpc.private_subnets
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}
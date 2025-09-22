############################################
# GitHub OIDC provider and CI roles (build, deploy, infra)
# Repository filter: yuvanreddy/flask-app
############################################

# GitHub OIDC provider
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    # GitHub's root CA thumbprint (2024) for token.actions.githubusercontent.com
    "6938fd4d98bab03faadb97b34396831e3780aea1"
  ]
}

locals {
  github_repo = "yuvanreddy/flask-app"
  oidc_sub    = "repo:${local.github_repo}:*"
}

# Trust policy allowing GitHub Actions in this repository to assume the role
locals {
  github_trust = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com",
          },
          StringLike = {
            "token.actions.githubusercontent.com:sub" = local.oidc_sub
          }
        }
      }
    ]
  })
}

# Build role: ECR push/pull
resource "aws_iam_role" "github_build" {
  name               = "github-build-role"
  assume_role_policy = local.github_trust
  tags = { Project = var.project_name }
}

resource "aws_iam_role_policy_attachment" "build_ecr_poweruser" {
  role       = aws_iam_role.github_build.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
}

# Deploy role: EKS access (kubectl/helm) + ECR get-login-password
resource "aws_iam_role" "github_deploy" {
  name               = "github-deploy-role"
  assume_role_policy = local.github_trust
  tags = { Project = var.project_name }
}

# Minimal policies for deploy: EKS describe, ECR auth, and STS
resource "aws_iam_policy" "deploy_policy" {
  name        = "github-deploy-policy"
  description = "Permissions for GitHub deploy to interact with EKS and ECR"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = [
          "eks:DescribeCluster",
          "eks:ListClusters"
        ],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = [
          "ecr:GetAuthorizationToken",
          "ecr:DescribeRepositories",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "deploy_attach" {
  role       = aws_iam_role.github_deploy.name
  policy_arn = aws_iam_policy.github_deploy_policy.arn
}

# Infra role: Terraform wide permissions (you can scope down later)
resource "aws_iam_role" "github_infra" {
  name               = "github-infra-role"
  assume_role_policy = local.github_trust
  tags = { Project = var.project_name }
}

# Attach common admin policy for infra (reduce scope later per need)
resource "aws_iam_role_policy_attachment" "infra_admin" {
  role       = aws_iam_role.github_infra.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

output "github_oidc_provider_arn" { value = aws_iam_openid_connect_provider.github.arn }
output "github_build_role_arn"     { value = aws_iam_role.github_build.arn }
output "github_deploy_role_arn"    { value = aws_iam_role.github_deploy.arn }
output "github_infra_role_arn"     { value = aws_iam_role.github_infra.arn }

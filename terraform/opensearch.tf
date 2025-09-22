############################################
# Amazon OpenSearch + Fluent Bit (aws-for-fluent-bit)
# - Creates OpenSearch domain inside VPC private subnets
# - Security Group allowing access from EKS node security group
# - IRSA role for Fluent Bit with SigV4 permissions to OpenSearch
# - Helm release: aws-for-fluent-bit configured to send to OpenSearch
############################################

locals {
  opensearch_domain_name = "${var.project_name}-logs"
}

# Security group for OpenSearch domain
resource "aws_security_group" "opensearch" {
  name        = "${var.project_name}-opensearch-sg"
  description = "Security group for OpenSearch domain"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Project = var.project_name
  }
}

# Allow HTTPS from EKS nodes to OpenSearch
resource "aws_security_group_rule" "opensearch_ingress_from_nodes" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.opensearch.id
  source_security_group_id = module.eks.node_security_group_id
  description              = "Allow EKS nodes to reach OpenSearch over TLS"
}

resource "aws_opensearch_domain" "logs" {
  domain_name    = local.opensearch_domain_name
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type  = "t3.small.search"
    instance_count = 2
    zone_awareness_enabled = true
    zone_awareness_config {
      availability_zone_count = 2
    }
  }

  ebs_options {
    ebs_enabled = true
    volume_type = "gp3"
    volume_size = 20
  }

  vpc_options {
    security_group_ids = [aws_security_group.opensearch.id]
    subnet_ids         = slice(module.vpc.private_subnets, 0, 2)
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https = true
    tls_security_policy = "Policy-Min-TLS-1-2-2019-07"
  }

  # Use IAM-based access (SigV4). Further restrict via resource-based policy if needed.
  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Principal = { AWS = "*" }
        Action   = [
          "es:ESHttpGet",
          "es:ESHttpHead",
          "es:ESHttpPost",
          "es:ESHttpPut",
          "es:ESHttpDelete"
        ]
        Resource = "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${local.opensearch_domain_name}/*"
        Condition = {
          StringEquals = {
            "aws:PrincipalAccount" = data.aws_caller_identity.current.account_id
          }
        }
      }
    ]
  })

  tags = {
    Project = var.project_name
  }
}

# IRSA role and policy for Fluent Bit to write to OpenSearch (SigV4)
module "fluentbit_irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.38"

  role_name = "${var.cluster_name}-fluent-bit"

  oidc_providers = {
    this = {
      provider_arn = module.eks.oidc_provider_arn
      namespace_service_accounts = [
        "kube-system:fluent-bit"
      ]
    }
  }

  # Additional inline policy for OpenSearch SigV4
  role_policy_statements = {
    es_access = {
      effect = "Allow"
      actions = [
        "es:ESHttpGet",
        "es:ESHttpHead",
        "es:ESHttpPost",
        "es:ESHttpPut",
        "es:ESHttpDelete"
      ]
      resources = [
        "arn:aws:es:${var.aws_region}:${data.aws_caller_identity.current.account_id}:domain/${local.opensearch_domain_name}/*"
      ]
    }
  }
}

# aws-for-fluent-bit Helm chart configured for OpenSearch output with SigV4
resource "helm_release" "aws_for_fluent_bit" {
  name       = "aws-for-fluent-bit"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-for-fluent-bit"
  namespace  = "kube-system"

  # Use our IRSA-annotated SA
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "serviceAccount.name"
    value = "fluent-bit"
  }
  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = module.fluentbit_irsa.iam_role_arn
  }

  # Disable other outputs
  set { name = "cloudWatch.enabled" value = "false" }
  set { name = "kinesis.enabled" value = "false" }
  set { name = "firehose.enabled" value = "false" }

  # Enable Elasticsearch(OpenSearch) output with SigV4
  set { name = "elasticsearch.enabled"  value = "true" }
  set { name = "elasticsearch.host"      value = aws_opensearch_domain.logs.endpoint }
  set { name = "elasticsearch.port"      value = "443" }
  set { name = "elasticsearch.scheme"    value = "https" }
  set { name = "elasticsearch.awsAuth"   value = "true" }
  set { name = "elasticsearch.awsRegion" value = var.aws_region }
  set { name = "elasticsearch.index"     value = "kubernetes-logs" }

  depends_on = [
    module.eks,
    aws_opensearch_domain.logs
  ]
}

output "opensearch_endpoint" {
  value = aws_opensearch_domain.logs.endpoint
}

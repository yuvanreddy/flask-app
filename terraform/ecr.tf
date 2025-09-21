############################################
# ECR Repository for application images
############################################
resource "aws_ecr_repository" "app" {
  name                 = var.ecr_repository_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project = var.project_name
  }
}

output "ecr_repository_url" {
  value = aws_ecr_repository.app.repository_url
}

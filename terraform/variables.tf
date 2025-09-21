variable "aws_region" {
  description = "The AWS region to deploy to."
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "The name of the project, used for resource naming."
  type        = string
  default     = "flask-devops"
}
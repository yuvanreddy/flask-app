DevOps Flask Application
This repository contains a simple "Hello, World!" Flask application designed to demonstrate a comprehensive DevOps workflow. The project leverages a modern technology stack to automate the entire software development lifecycle, from code commit to deployment.

Technology Stack
Application: Python (Flask)

Containerization: Docker

Cloud Provider: Amazon Web Services (AWS)

Infrastructure as Code: Terraform

CI/CD: GitHub Actions

Container Orchestration: Kubernetes (managed by Rancher)

Monitoring: Prometheus & Grafana

Logging: ELK Stack (Elasticsearch, Logstash, Kibana)

Repository Structure
The project is organized into the following key directories:

app/: Contains the Flask application code and its dependencies.

.github/workflows/: Stores the GitHub Actions workflow for CI/CD.

terraform/: Holds the Terraform configuration files for provisioning AWS infrastructure.

k8s/: Contains the Kubernetes manifest files for deploying the application.

Workflow Overview
A developer pushes code to the main branch.

The GitHub Actions workflow is triggered.

Build & Push: The workflow builds a Docker image of the Flask app and pushes it to an AWS ECR container registry.

Infrastructure Provisioning: Terraform is executed to provision the necessary AWS resources, including a VPC, subnets, and an EKS cluster.

Deployment: The Kubernetes manifests are applied to the EKS cluster, deploying the application.

Monitoring & Logging:

Prometheus & Grafana: The Kubernetes manifests should be configured to integrate with an existing Prometheus/Grafana stack to scrape metrics from the application pods.

ELK Stack: A sidecar container or a DaemonSet for Logstash/Fluentd is used to collect logs from the application and forward them to the Elasticsearch cluster.

Getting Started
Prerequisites
An AWS account with configured credentials.

GitHub repository.

Docker installed locally.

Kubernetes CLI (kubectl) configured to connect to your cluster.

Terraform installed locally.

Setup
Repository Secrets: In your GitHub repository settings, add the following secrets for GitHub Actions:

AWS_ACCESS_KEY_ID

AWS_SECRET_ACCESS_KEY

AWS_ACCOUNT_ID

KUBE_CONFIG (Base64 encoded ~/.kube/config file with cluster access)

Terraform Configuration:

Navigate to the terraform/ directory.

Update main.tf with your desired resource names and tags.

Run terraform init to initialize the project.

Run terraform apply to provision the AWS infrastructure.

Kubernetes Deployment:

After the Terraform EKS cluster is created, configure kubectl to connect to it.

Update the k8s/deployment.yaml and k8s/service.yaml files with your specific image name and other configurations.

Run kubectl apply -f k8s/ to deploy the application.

Rancher, Prometheus & ELK:

The setup for these components is highly specific to your environment. This project provides the groundwork, and you will need to follow the official documentation to integrate them with your Kubernetes cluster.

Rancher: Import the EKS cluster into your Rancher dashboard.

Prometheus: Install the Prometheus Operator on your cluster to manage monitoring resources.

ELK Stack: Deploy the Elasticsearch cluster and configure a log shipper (e.g., Filebeat, Fluentd) as a DaemonSet to collect logs from all nodes.
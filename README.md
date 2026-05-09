# Java App CI/CD Pipeline — Jenkins + Docker + ECR + Terraform + ECS Fargate

A fully automated CI/CD pipeline that builds a simple-web-application, packages it into a Docker image, pushes it to AWS ECR, and deploys it to AWS ECS Fargate using Terraform — all orchestrated via Jenkins.

---

# Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Infrastructure Overview](#infrastructure-overview)
- [Pipeline Stages](#pipeline-stages)
- [Environment Variables & Secrets](#environment-variables--secrets)
- [Terraform Variables](#terraform-variables)
- [How to Run](#how-to-run)
- [Security Best Practices](#security-best-practices)
- [Troubleshooting](#troubleshooting)
---
# Architecture Overview

```
Developer Push
      │
      ▼
  GitHub Repo
      │
      ▼
  Jenkins Pipeline
      │
      ├── 1. Checkout Code
      ├── 2. Maven Build (JAR) 
      |-- 3. run test
      ├── 4. Docker Build (Image)
      |-- 5. Terraform Apply - ECR Only
      ├── 6. Push to AWS ECR
      ├── 7. Terraform Init / Validate / Plan
      |-- 8. Terraform Validate
      |-- 9. Terraform Plan
      └── 10. Terraform Apply - full deploy
                                    │
                                    ▼
                             ALB (Port 80)
                                    │
                                    ▼
                         ECS Fargate Task (Port 8080)
```

**AWS Services Used:**
- **ECR** — Container image registry
- **ECS Fargate** — Serverless container runtime
- **ALB** — Application Load Balancer (internet-facing)
- **VPC** — Custom network with public subnets across 2 AZs
- **IAM** — Task execution role + task role (least privilege)
- **CloudWatch** — Container log aggregation
---
# Prerequisites

# Tools Required
| Tool | Version | Purpose |
|------|---------|---------|
| Jenkins | 2.400+ | CI/CD orchestration |
| Maven | 3.x | Java build tool |
| Docker | 20+ | Container build & push |
| Terraform | 1.5+ | Infrastructure as Code |
| AWS CLI | 2.x | AWS authentication |
| Java | 11 or 17 | Application runtime |

# Jenkins Plugins Required
- Pipeline
- Git
- Maven Integration
- AWS Credentials Plugin
- Docker Pipeline

# AWS Requirements
- An AWS account with permissions for: ECR, ECS, IAM, VPC, ALB, CloudWatch
- An existing ECR repository (e.g., `terra-ecr`)
- Jenkins server (EC2 recommended — attach IAM role to avoid key management)

---

# Project Structure

```
.
├── Jenkinsfile               # CI/CD pipeline definition
├── Dockerfile                # Docker image build instructions
├── pom.xml                   # Maven project config
├── src/                      # Java application source
├── main.tf                   # Core Terraform resources
├── provider.tf               # AWS provider config
├── variables.tf              # Input variable declarations
├── data.tf                   # Data sources (ECR lookup)
├── outputs.tf                # Terraform outputs (ALB DNS)
├── terraform.tfvars          # Non-secret variable values (do NOT commit secrets)
└── README.md                 # This file
```
---
# Infrastructure Overview
# Networking
- **VPC** CIDR: `10.0.0.0/16`
- **Public Subnet A**: `10.0.1.0/24` (us-east-1a)
- **Public Subnet B**: `10.0.2.0/24` (us-east-1b)
- **Internet Gateway** attached to VPC
- **Route Table** with `0.0.0.0/0` → Internet Gateway

# Security Group
| Direction | Port | Protocol | Source |
|-----------|------|----------|--------|
| Inbound   | 8080 | TCP      | 0.0.0.0/0 |
| Outbound  | All  | All      | 0.0.0.0/0 |

# ECS Fargate
- **Cluster**: `{environment}-fargate-cluster`
- **Task CPU**: 256 units
- **Task Memory**: 512 MB
- **Container Port**: 8080
- **Launch Type**: FARGATE
- **Desired Count**: 1

# Load Balancer
- **Type**: Application Load Balancer (internet-facing)
- **Listener**: Port 80 (HTTP)
- **Target Group**: Port 8080, target type `ip`
- **Health Check**: `GET /` → expects `200-399`
---
# Pipeline Stages

| Stage | Description |
|-------|-------------|
| **Checkout** | Pulls latest code from source control |
| **Build with Maven** | Runs `mvn install -DskipTests` to produce JAR |
| **Docker Build** | Builds Docker image tagged with `BUILD_NUMBER` |
| **Push to ECR** | Authenticates with ECR and pushes image |
| **Terraform Init** | Initializes Terraform backend and providers |
| **Terraform Validate** | Validates Terraform configuration syntax |
| **Terraform Plan** | Creates execution plan, outputs to `tfplan` |
| **Terraform Apply** | Deploys/updates ECS Fargate infrastructure |
| **Post-Deploy Info** | Prints Terraform outputs (ALB DNS name) |
---
# Environment Variables & Secrets

# Jenkins Credentials to Configure
Go to **Jenkins → Manage Jenkins → Credentials → Global** and add:

| Credential ID | Type | Description |
|---------------|------|-------------|
| `aws-credentials` | AWS Credentials | Access Key + Secret Key |
| `aws-account-id` | Secret Text | AWS Account ID |
| `aws-region` | Secret Text | Target AWS region |
| `ecr-repo-name` | Secret Text | ECR repository name |

# Jenkinsfile Environment Block (no hardcoding)
```groovy
environment {
    MAVEN_OPTS     = "-Dmaven.repo.local=/var/lib/jenkins/.m2/repository"
    AWS_REGION     = credentials('aws-region')
    AWS_ACCOUNT_ID = credentials('aws-account-id')
    ECR_REPO       = credentials('ecr-repo-name')
    IMAGE_TAG      = "${BUILD_NUMBER}"
    TF_DIR         = '.'
}
```
> **Never hardcode AWS Access Keys, Secret Keys, or Account IDs in the Jenkinsfile or Terraform files.**

# Recommended: Use IAM Instance Role
If Jenkins runs on EC2, attach an IAM role with the following policies instead of using access keys:
- `AmazonEC2ContainerRegistryFullAccess`
- `AmazonECS_FullAccess`
- `IAMFullAccess` (or scoped-down custom policy)
---
# Terraform Variables
# `variables.tf` — All input variables

| Variable | Type | Default | Description |
|----------|------|---------|-------------|
| `aws_region` | string | `us-east-1` | AWS deployment region |
| `aws_account_id` | string | — | AWS Account ID (no default — pass via pipeline) |
| `ecr_repo` | string | `terra-ecr` | ECR repository name |
| `image_tag` | string | `latest` | Docker image tag (set to BUILD_NUMBER in pipeline) |
| `environment` | string | `dev` | Environment name (dev/staging/prod) |
| `cpu` | string | `256` | Fargate task CPU units |
| `memory` | string | `512` | Fargate task memory (MB) |
| `desired_count` | number | `1` | Number of running ECS tasks |

# `terraform.tfvars` — Example (non-secret values only)
```hcl
aws_region     = "us-east-1"
ecr_repo       = "terra-ecr"
environment    = "dev"
cpu            = "256"
memory         = "512"
desired_count  = 1
```

> Add `terraform.tfvars` to `.gitignore` if it contains any sensitive values.

---

# How to Run

# 1. Clone the Repository
```bash
git clone https://github.com/your-org/your-repo.git
cd your-repo
```

# 2. Set Up Jenkins Credentials
Add all credentials listed in the [Environment Variables](#environment-variables--secrets) section to Jenkins.

# 3. Create ECR Repository (one-time)
```bash
aws ecr create-repository --repository-name terra-ecr --region us-east-1
```

# 4. Configure Jenkins Pipeline
- Create a new **Pipeline** job in Jenkins
- Set **Pipeline script from SCM**
- Point to your repository and set script path to `Jenkinsfile`

# 5. Trigger the Pipeline
Push a commit or manually trigger the build in Jenkins. The pipeline will:
1. Build the JAR
2. Build and push the Docker image
3. Deploy infrastructure via Terraform
4. Output the ALB DNS name

# 6. Access the Application
After a successful run, get the ALB DNS from Terraform output:
```bash
terraform output alb_dns_name
```
Then visit: `http://<alb-dns-name>/`

---

#  Security Best Practices

-  Never hardcode AWS credentials in code or pipelines
-  Use Jenkins Credentials store for all secrets
-  Prefer IAM Instance Roles over access keys
-  Keep `execution_role` and `task_role` separate (least privilege)
-  Add `terraform.tfvars` to `.gitignore`
-  Enable CloudWatch logging for all ECS containers
-  Rotate AWS access keys regularly if used
-  Use specific image tags (BUILD_NUMBER), never `latest` in production
-  Enable ALB access logs for audit trail
-  Restrict security group ingress to known IPs in production
---
# Troubleshooting
# Docker build fails
```bash
# Ensure Docker daemon is running on Jenkins agent
sudo systemctl start docker
sudo usermod -aG docker jenkins
```
# ECR push fails — authentication error
```bash
# Verify region matches ECR repository region
aws ecr get-login-password --region us-east-1 | \
  docker login --username AWS --password-stdin \
  <account_id>.dkr.ecr.us-east-1.amazonaws.com
```
# Terraform plan fails — variable not set
```bash
# Pass missing variables explicitly
terraform plan -var "aws_account_id=<your-id>" -var "image_tag=<tag>"
```
# ECS task keeps stopping
- Check CloudWatch logs: `/ecs/{environment}-fargate-task`
- Verify container port matches ALB target group port (8080)
- Confirm the JAR starts correctly on port 8080

# ALB returns 502 Bad Gateway
- ECS task may still be starting (wait ~60 seconds)
- Check health check path returns `200-399`
- Verify security group allows traffic on port 8080

# Outputs

| Output | Description |
|--------|-------------|
| `alb_dns_name` | Public DNS name of the Application Load Balancer |

# Author

**Ezea Chigozie**
DevOps Engineer
> Built with Jenkins • Terraform • Docker • AWS ECS Fargate
#   p r o j e c t  
 
variable "environment" {
  description = "Deployment environment"
  type        = string
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "image_url" {
  description = "Full ECR image URL including tag"
  type        = string
}

variable "cpu" {
  description = "Fargate task CPU units"
  type        = string
  default     = "256"
}

variable "memory" {
  description = "Fargate task memory in MB"
  type        = string
  default     = "512"
}

variable "desired_count" {
  description = "Number of ECS tasks to run"
  type        = number
  default     = 1
}

variable "container_port" {
  description = "Port the container listens on"
  type        = number
  default     = 8080
}

# Passed in from networking module outputs
variable "vpc_id" {
  description = "VPC ID from networking module"
  type        = string
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs from networking module"
  type        = list(string)
}

variable "security_group_id" {
  description = "Security group ID from networking module"
  type        = string
}

variable "ecr_repo" {
  description = "Name of the ECR repository"
  type        = string
  default     = "terra-ecr"
}

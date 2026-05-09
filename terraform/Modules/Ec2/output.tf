output "alb_dns_name" {
  description = "Public DNS name of the ALB"
  value       = aws_lb.alb.dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = aws_ecs_cluster.fargate_cluster.name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = aws_ecs_service.fargate_service.name
}

output "ecr_repository_url" {
  description = "ECR repository URL"
  value       = aws_ecr_repository.app.repository_url
}

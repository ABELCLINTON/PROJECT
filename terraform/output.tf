output "alb_dns_name" {
  description = "Public DNS — access your app here"
  value       = module.ec2.alb_dns_name
}

output "ecs_cluster_name" {
  description = "ECS cluster name"
  value       = module.ec2.ecs_cluster_name
}

output "ecs_service_name" {
  description = "ECS service name"
  value       = module.ec2.ecs_service_name
}

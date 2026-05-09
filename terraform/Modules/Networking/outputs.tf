output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.fargate_vpc.id
}

output "public_subnet_a_id" {
  description = "Public Subnet A ID"
  value       = aws_subnet.public_subnet_a.id
}

output "public_subnet_b_id" {
  description = "Public Subnet B ID"
  value       = aws_subnet.public_subnet_b.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = [aws_subnet.public_subnet_a.id, aws_subnet.public_subnet_b.id]
}

output "security_group_id" {
  description = "Fargate security group ID"
  value       = aws_security_group.fargate_sg.id
}

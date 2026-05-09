module "networking" {
  source         = "./modules/networking"
  environment    = var.environment
  aws_region     = var.aws_region
  container_port = var.container_port
}

module "ec2" {
  source            = "./modules/ec2"
  environment       = var.environment
  aws_region        = var.aws_region
  image_url         = "${module.ec2.ecr_repository_url}:${var.image_tag}"
  cpu               = var.cpu
  memory            = var.memory
  desired_count     = var.desired_count
  container_port    = var.container_port

  # Passed from networking module
  vpc_id            = module.networking.vpc_id
  public_subnet_ids = module.networking.public_subnet_ids
  security_group_id = module.networking.security_group_id
}

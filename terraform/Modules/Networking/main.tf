# VPC
resource "aws_vpc" "fargate_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.environment}-fargate-vpc" }
}

# SUBNETS
resource "aws_subnet" "public_subnet_a" {
  vpc_id                  = aws_vpc.fargate_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}a"
  tags = { Name = "${var.environment}-public-a" }
}

resource "aws_subnet" "public_subnet_b" {
  vpc_id                  = aws_vpc.fargate_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "${var.aws_region}b"
  tags = { Name = "${var.environment}-public-b" }
}

# INTERNET GATEWAY & ROUTE TABLE
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.fargate_vpc.id
  tags   = { Name = "${var.environment}-igw" }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.fargate_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = { Name = "${var.environment}-public-rt" }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public_subnet_a.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.public_subnet_b.id
  route_table_id = aws_route_table.public_rt.id
}

# SECURITY GROUP
resource "aws_security_group" "fargate_sg" {
  vpc_id = aws_vpc.fargate_vpc.id
  name   = "${var.environment}-fargate-sg"

  ingress {
    from_port   = var.container_port
    to_port     = var.container_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.environment}-fargate-sg" }
}

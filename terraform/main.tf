provider "aws" {
  region = "us-west-2"
}

# VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main_vpc"
  }
}

# Subnets
resource "aws_subnet" "public_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet"
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "private_subnet"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main_igw"
  }
}

# Route Tables
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public_rt"
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# EKS Cluster Setup with Correct Worker Groups Definition
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.1.0"
  cluster_name    = "my-cluster"
  cluster_version = "1.26"
  vpc_id          = aws_vpc.main_vpc.id
  subnets         = [aws_subnet.public_subnet.id, aws_subnet.private_subnet.id]

  worker_groups = [
    {
      name                 = "eks_nodes"
      instance_type        = "t3.medium"
      asg_desired_capacity = 2
      asg_min_size         = 1
      asg_max_size         = 3
    }
  ]

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}

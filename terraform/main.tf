
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

# Public Subnet in AZ1
resource "aws_subnet" "public_subnet_az1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.10.0/24"
  availability_zone       = "us-west-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_az1"
  }
}

# Public Subnet in AZ2
resource "aws_subnet" "public_subnet_az2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.20.0/24"
  availability_zone       = "us-west-2b"
  map_public_ip_on_launch = true

  tags = {
    Name = "public_subnet_az2"
  }
}

# Private Subnet in AZ1
resource "aws_subnet" "private_subnet_az1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.30.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "private_subnet_az1"
  }
}

# Private Subnet in AZ2
resource "aws_subnet" "private_subnet_az2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = "10.0.40.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "private_subnet_az2"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main_igw"
  }
}

# Route Table for Public Subnets
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

resource "aws_route_table_association" "public_rt_assoc_az1" {
  subnet_id      = aws_subnet.public_subnet_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_assoc_az2" {
  subnet_id      = aws_subnet.public_subnet_az2.id
  route_table_id = aws_route_table.public_rt.id
}

# Security Group for CI/CD Instance
resource "aws_security_group" "ci_cd_sg" {
  vpc_id = aws_vpc.main_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 8081
    to_port     = 8081
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ci_cd_sg"
  }
}

resource "aws_instance" "ci_cd_instance" {
  ami                    = "ami-05134c8ef96964280"  # Use the appropriate Ubuntu AMI
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public_subnet_az1.id  # Replace with your subnet
  vpc_security_group_ids = [aws_security_group.ci_cd_sg.id] # Use vpc_security_group_ids instead of security_group_ids
  associate_public_ip_address = true

  tags = {
    Name = "CI_CD_Server"
  }
}

# IAM Role for EKS Workers
resource "aws_iam_role" "eks_worker_role" {
  name = "eks_worker_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })

  tags = {
    Name = "eks_worker_role"
  }
}

# Attach Policies to IAM Role
resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_cni_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "ec2_container_registry_policy" {
  role       = aws_iam_role.eks_worker_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# EKS Cluster Setup with Worker Groups
module "eks" {
  source          = "terraform-aws-modules/eks/aws"
  version         = "17.1.0"
  cluster_name    = "my-cluster"
  cluster_version = "1.26"
  vpc_id          = aws_vpc.main_vpc.id
  subnets         = [
    aws_subnet.public_subnet_az1.id, 
    aws_subnet.public_subnet_az2.id, 
    aws_subnet.private_subnet_az1.id, 
    aws_subnet.private_subnet_az2.id
  ]

  worker_groups = [
    {
      name                 = "eks_nodes"
      instance_type        = "t3.medium"
      asg_desired_capacity = 2
      asg_min_size         = 1
      asg_max_size         = 3
      iam_role_name        = aws_iam_role.eks_worker_role.name
    }
  ]

  tags = {
    Environment = "production"
    Project     = "my-project"
  }
}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.main.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.main.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.main.token
}

data "aws_eks_cluster" "main" {
  name = module.eks.cluster_id
}

data "aws_eks_cluster_auth" "main" {
  name = module.eks.cluster_id
}

# ECR Repository
resource "aws_ecr_repository" "tours_and_travels" {
  name                 = "tours-and-travels-in-php"
  image_tag_mutability = "MUTABLE"

  tags = {
    Name        = "tours-and-travels-in-php"
    Environment = "production"
  }
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.tours_and_travels.repository_url
  description = "URL of the ECR repository"
}

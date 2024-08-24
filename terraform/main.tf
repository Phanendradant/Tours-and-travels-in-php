
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
    from_port   = 8080
    to_port     = 8080
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

# EC2 Instance for Jenkins, Docker, and kubectl
resource "aws_instance" "ci_cd_instance" {
  ami                    = "ami-0c55b159cbfafe1f0"  # Use the appropriate Ubuntu AMI
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public_subnet_az1.id  # Replace with your subnet
  security_group_ids     = [aws_security_group.ci_cd_sg.id]
  associate_public_ip_address = true

  # User data script to install Jenkins, Docker, and kubectl
  user_data = <<-EOF
    #!/bin/bash

# Update and upgrade the instance
sudo apt-get update -y
sudo apt-get upgrade -y

# Install Docker
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update -y
sudo apt-get install -y docker-ce
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ubuntu

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian/jenkins.io.key | sudo tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian binary/ | sudo tee /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update -y
sudo apt-get install -y jenkins
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Add Jenkins user to Docker group
sudo usermod -aG docker jenkins

# Install necessary Jenkins plugins (optional)
sudo su - jenkins -s /bin/bash -c "curl -L https://get.jenkins.io/war-stable/2.332.2/jenkins.war -o /var/lib/jenkins/jenkins.war"
sudo su - jenkins -s /bin/bash -c "java -jar /var/lib/jenkins/jenkins.war --httpPort=8080 &"

# Open necessary ports for Jenkins and Docker
sudo ufw allow 8080  # Jenkins
sudo ufw allow 2376  # Docker
sudo ufw enable

# Clone your repository and set up Jenkins job (manual steps may be required)
# Note: Replace the following repository URL with your actual repository
cd /var/lib/jenkins
git clone https://github.com/Phanendradant/Tours-and-travels-in-php.git

# Example to add a Jenkins job via Jenkins CLI or by configuring through the Jenkins UI:
# You can configure a Jenkins job manually via the UI to build and deploy the Docker image using the Dockerfile.

  EOF

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

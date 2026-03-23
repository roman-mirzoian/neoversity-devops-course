terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
  required_version = ">= 1.4"
}

provider "aws" {
  region = local.region
  # profile = "default"                  # optional, if you use named profile
  # shared_credentials_file = "~/.aws/credentials"  # optional
}

locals {
  cluster_name = "lesson-7-eks"
  region       = "us-west-2"
}

# Підключаємо модуль для S3 та DynamoDB
module "s3-backend" {
  source      = "./modules/s3-backend"          # Шлях до модуля
  bucket_name = "terraform-state-bucket-001001" # Ім'я S3-бакета
  table_name  = "terraform-locks"               # Ім'я DynamoDB
}

# Підключаємо модуль для VPC
module "vpc" {
  source              = "./modules/vpc"           # Шлях до модуля VPC
  vpc_cidr_block      = "10.0.0.0/16"             # CIDR блок для VPC
  public_subnets      = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]        # Публічні підмережі
  private_subnets     = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]         # Приватні підмережі
  availability_zones  = ["us-west-2a", "us-west-2b", "us-west-2c"]            # Зони доступності
  vpc_name            = "vpc"              # Ім'я VPC
  cluster_name        = local.cluster_name
}

# Підключаємо модуль для ECR
module "ecr" {
  source            = "./modules/ecr"
  repository_name   = "lesson-5-app"
  image_tag_mutability = "MUTABLE"
  scan_on_push      = true
}

# Підключаємо модуль для EKS
module "eks" {
  source                = "./modules/eks"
  cluster_name          = local.cluster_name
  cluster_version       = "1.29"
  region                = local.region
  subnet_ids            = module.vpc.private_subnets
  node_subnet_ids       = module.vpc.private_subnets
  node_desired_size     = 2
  node_min_size         = 2
  node_max_size         = 6
  node_instance_types   = ["t3.medium"]
  node_capacity_type    = "ON_DEMAND"
  node_disk_size        = 20
}

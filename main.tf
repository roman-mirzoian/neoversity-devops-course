terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.27"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
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

data "aws_eks_cluster" "this" {
  name       = local.cluster_name
  depends_on = [module.eks]
}

data "aws_eks_cluster_auth" "this" {
  name       = local.cluster_name
  depends_on = [module.eks]
}

data "aws_caller_identity" "current" {}

provider "kubernetes" {
  host                   = data.aws_eks_cluster.this.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.this.token
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.this.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.this.token
  }
}

# Підключаємо модуль для S3 та DynamoDB
module "s3-backend" {
  source      = "./modules/s3-backend"          # Шлях до модуля
  bucket_name = "terraform-state-bucket-001001" # Ім'я S3-бакета
  table_name  = "terraform-locks"               # Ім'я DynamoDB
}

# Підключаємо модуль для VPC
module "vpc" {
  source             = "./modules/vpc"
  vpc_cidr_block     = "10.0.0.0/16"
  public_subnets     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  private_subnets    = ["10.0.4.0/24", "10.0.5.0/24", "10.0.6.0/24"]
  availability_zones = ["us-west-2a", "us-west-2b", "us-west-2c"]
  vpc_name           = "vpc"
  cluster_name       = local.cluster_name
}

# Підключаємо модуль для ECR
module "ecr" {
  source               = "./modules/ecr"
  repository_name      = "lesson-5-app"
  image_tag_mutability = "MUTABLE"
  scan_on_push         = true
}

# Підключаємо модуль для EKS
module "eks" {
  source              = "./modules/eks"
  cluster_name        = local.cluster_name
  cluster_version     = "1.29"
  region              = local.region
  subnet_ids          = module.vpc.private_subnets
  node_subnet_ids     = module.vpc.private_subnets
  node_desired_size   = 2
  node_min_size       = 2
  node_max_size       = 6
  node_instance_types = ["t3.medium"]
  node_capacity_type  = "ON_DEMAND"
  node_disk_size      = 20

  providers = {
    aws = aws
    tls = tls
  }
}

# Підключення для Jenkins
module "jenkins" {
  source = "./modules/jenkins"

  namespace               = "jenkins"
  chart_version           = "5.1.25"
  admin_user              = "admin"
  admin_password          = var.jenkins_admin_password
  cluster_name            = local.cluster_name
  cluster_oidc_issuer_url = module.eks.cluster_oidc_issuer_url
  ecr_repository_arn      = module.ecr.repository_arn
  aws_region              = local.region
  aws_account_id          = data.aws_caller_identity.current.account_id
  git_repo_url            = var.git_repo_url

  providers = {
    kubernetes = kubernetes
    helm       = helm
    aws        = aws
  }

  depends_on = [module.eks]
}

# Підключення для Argo CD
module "argo_cd" {
  source = "./modules/argo_cd"

  namespace            = "argocd"
  chart_version        = "6.7.11"
  git_repo_url         = var.git_repo_url
  target_revision      = "main"
  django_app_path      = "charts/django-app"
  django_app_namespace = "default"

  providers = {
    kubernetes = kubernetes
    helm       = helm
  }

  depends_on = [module.eks]
}

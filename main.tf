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

# Підключення для RDS
module "rds" {
  source = "./modules/rds"

  identifier  = "lesson-7-django-db"
  use_aurora  = false

  engine         = "postgres"
  engine_version = "14.10"
  instance_class = "db.t3.medium"

  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  allowed_cidr_blocks = ["10.0.0.0/16"] # VPC CIDR

  database_name   = "djangodb"
  master_username = "dbadmin"
  master_password = var.db_password

  allocated_storage     = 20
  max_allocated_storage = 100
  storage_type          = "gp3"
  multi_az              = false

  storage_encrypted       = true
  deletion_protection     = false
  skip_final_snapshot     = true
  backup_retention_period = 7

  tags = {
    Project     = "lesson-7"
    Environment = "dev"
  }

  depends_on = [module.vpc]
}

# Підключаємо модуль для моніторингу (Prometheus + Grafana + Alertmanager)
# Доступ: kubectl port-forward svc/kube-prometheus-stack-grafana 3000:80 -n monitoring
module "monitoring" {
  source = "./modules/monitoring"

  namespace              = "monitoring"
  chart_version          = "56.21.4"
  grafana_admin_password = var.grafana_admin_password

  prometheus_retention      = "15d"
  prometheus_storage_size   = "20Gi"
  grafana_storage_size      = "5Gi"
  alertmanager_storage_size = "2Gi"
  storage_class             = "gp2"

  providers = {
    kubernetes = kubernetes
    helm       = helm
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

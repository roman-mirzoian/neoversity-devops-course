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
  region = "us-east-1"
  # profile = "default"                  # optional, if you use named profile
  # shared_credentials_file = "~/.aws/credentials"  # optional
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
}


# Lesson 5: Terraform AWS Infrastructure

## Опис структури проекту

- `main.tf` - підключення модулів та провайдер AWS
- `backend.tf` - налаштування S3 + DynamoDB бекенду для стану Terraform
- `outputs.tf` - загальні output’и з усіх модулів
- `modules/s3-backend` - S3 бакет з версіонуванням + DynamoDB таблиця для блокування
- `modules/vpc` - VPC з 3 публічними та 3 приватними підмережами, IGW, NAT GW, маршрутами
- `modules/ecr` - ECR репозиторій з автоматичним скануванням та політикою доступу

## Команди для ініціалізації та запуску

1. `terraform init`
2. `terraform plan`
3. `terraform apply -auto-approve`
4. `terraform destroy -auto-approve`

## Пояснення модулів

### s3-backend

- `aws_s3_bucket` з включеним `aws_s3_bucket_versioning`
- `aws_dynamodb_table` для блокування стейту
- `aws_s3_bucket_ownership_controls` для безпечної власності об’єктів

### vpc

- `aws_vpc` з CIDR-блоком (10.0.0.0/16)
- 3 публічні підмережі + 3 приватні підмережі
- `aws_internet_gateway` + `aws_route_table` для публічних підмереж
- `aws_nat_gateway` у першій публічній підмережі + `aws_eip`
- `aws_route_table` для приватних підмереж з маршрутом через NAT Gateway

### ecr

- `aws_ecr_repository` з `image_scanning_configuration.scan_on_push = true`
- `aws_ecr_repository_policy` для базового pull-доступу

## Примітки

- Бекенд в `backend.tf`:
  - `bucket = "terraform-state-bucket-001001"`
  - `key = "lesson-5/terraform.tfstate"`
  - `region = "us-west-2"`
  - `dynamodb_table = "terraform-locks"`
  - `encrypt = true`

- Регiон провайдера встановлено `us-west-2` для згоди з зонами доступності.

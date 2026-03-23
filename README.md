# Lesson 7: Terraform AWS Infrastructure + EKS + Helm

## Опис структури проєкту

- `main.tf` - підключення модулів та провайдер AWS
- `backend.tf` - налаштування S3 + DynamoDB бекенду для стану Terraform
- `outputs.tf` - загальні outputs з усіх модулів
- `modules/s3-backend` - S3 бакет + DynamoDB таблиця для блокування
- `modules/vpc` - VPC з 3 публічними та 3 приватними підмережами, IGW, NAT GW, маршрутами та EKS тегами
- `modules/ecr` - ECR репозиторій
- `modules/eks` - EKS кластер та node group
- `charts/django-app` - Helm chart (Deployment, Service, HPA, ConfigMap)

## Команди для Terraform

1. `terraform init`
2. `terraform plan`
3. `terraform apply -auto-approve`

Після створення EKS:

1. `aws eks update-kubeconfig --name lesson-7-eks --region us-west-2`
2. `kubectl get nodes`

## ECR: завантаження Docker-образу

1. `aws ecr get-login-password --region us-west-2 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.us-west-2.amazonaws.com`
2. `docker build -t lesson-5-app .`
3. `docker tag lesson-5-app:latest <account-id>.dkr.ecr.us-west-2.amazonaws.com/lesson-5-app:latest`
4. `docker push <account-id>.dkr.ecr.us-west-2.amazonaws.com/lesson-5-app:latest`

## Helm: деплой Django застосунку

1. Вкажіть свій ECR репозиторій у `charts/django-app/values.yaml`
2. Оновіть `config.env` у `charts/django-app/values.yaml` змінними з теми 4
3. `helm upgrade --install django-app ./charts/django-app -f ./charts/django-app/values.yaml`
4. `kubectl get svc`
5. `kubectl get hpa`

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
- теги підмереж для EKS (`kubernetes.io/cluster/*`, `kubernetes.io/role/elb`, `kubernetes.io/role/internal-elb`)

### ecr

- `aws_ecr_repository` з `image_scanning_configuration.scan_on_push = true`
- `aws_ecr_repository_policy` для базового pull-доступу

### eks

- `aws_eks_cluster` з приватними підмережами
- `aws_eks_node_group` з autoscaling 2-6
- IAM ролі та політики для кластера і нод

## Примітки

- Бекенд в `backend.tf`:
  - `bucket = "terraform-state-bucket-001001"`
  - `key = "lesson-7/terraform.tfstate"`
  - `region = "us-west-2"`
  - `dynamodb_table = "terraform-locks"`
  - `encrypt = true`

- Регiон провайдера встановлено `us-west-2` для згоди з зонами доступності.

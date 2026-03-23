output "s3_bucket_name" {
  description = "Назва S3-бакета для стейтів"
  value       = module.s3-backend.s3_bucket_name
}

output "dynamodb_table_name" {
  description = "Назва таблиці DynamoDB для блокування стейтів"
  value       = module.s3-backend.dynamodb_table_name
}

output "ecr_repository_url" {
  description = "URL репозиторію ECR"
  value       = module.ecr.repository_url
}

output "eks_cluster_name" {
  description = "Назва EKS кластера"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "Endpoint EKS кластера"
  value       = module.eks.cluster_endpoint
}

output "eks_kubeconfig_command" {
  description = "Команда для оновлення kubeconfig"
  value       = module.eks.kubeconfig_command
}

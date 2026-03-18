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


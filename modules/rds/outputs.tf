output "endpoint" {
  description = "Основний endpoint для підключення до БД (writer для Aurora, single endpoint для RDS)"
  value       = var.use_aurora ? try(aws_rds_cluster.this[0].endpoint, null) : try(aws_db_instance.this[0].endpoint, null)
}

output "port" {
  description = "Порт для підключення до БД (5432 для PostgreSQL, 3306 для MySQL)"
  value       = local.db_port
}

output "database_name" {
  description = "Назва початкової бази даних"
  value       = var.database_name
}

output "master_username" {
  description = "Ім'я майстер-користувача БД"
  value       = var.master_username
  sensitive   = true
}

output "rds_endpoint" {
  description = "Повний endpoint стандартного RDS instance (host:port). null для Aurora"
  value       = try(aws_db_instance.this[0].endpoint, null)
}

output "rds_address" {
  description = "Hostname стандартного RDS instance (без порту). null для Aurora"
  value       = try(aws_db_instance.this[0].address, null)
}

output "rds_id" {
  description = "ID стандартного RDS instance. null для Aurora"
  value       = try(aws_db_instance.this[0].id, null)
}

output "aurora_cluster_endpoint" {
  description = "Writer endpoint Aurora кластера (для запитів на запис). null для стандартного RDS"
  value       = try(aws_rds_cluster.this[0].endpoint, null)
}

output "aurora_reader_endpoint" {
  description = "Reader endpoint Aurora кластера (балансування read-only запитів). null для стандартного RDS"
  value       = try(aws_rds_cluster.this[0].reader_endpoint, null)
}

output "aurora_cluster_id" {
  description = "ID Aurora кластера. null для стандартного RDS"
  value       = try(aws_rds_cluster.this[0].id, null)
}

output "aurora_cluster_arn" {
  description = "ARN Aurora кластера. null для стандартного RDS"
  value       = try(aws_rds_cluster.this[0].arn, null)
}

output "aurora_instance_ids" {
  description = "Список ID Aurora instances. Порожній список для стандартного RDS"
  value       = [for i in aws_rds_cluster_instance.this : i.id]
}

output "security_group_id" {
  description = "ID Security Group для RDS"
  value       = aws_security_group.this.id
}

output "subnet_group_name" {
  description = "Назва DB Subnet Group"
  value       = aws_db_subnet_group.this.name
}

output "parameter_group_name" {
  description = "Назва активної DB Parameter Group (instance PG для Aurora, стандартна PG для RDS)"
  value       = var.use_aurora ? try(aws_db_parameter_group.aurora_instance[0].name, null) : try(aws_db_parameter_group.rds[0].name, null)
}

output "connection_string" {
  description = "Рядок підключення у форматі DATABASE_URL (пароль прихований)"
  value = format(
    "%s://%s:***@%s:%d/%s",
    var.engine == "postgres" ? "postgresql" : "mysql",
    var.master_username,
    var.use_aurora ? try(aws_rds_cluster.this[0].endpoint, "") : try(aws_db_instance.this[0].address, ""),
    local.db_port,
    var.database_name
  )
}

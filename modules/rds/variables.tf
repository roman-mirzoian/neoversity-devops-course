variable "identifier" {
  description = "Унікальний ідентифікатор для RDS/Aurora (використовується як prefix у назвах ресурсів)"
  type        = string
}

variable "use_aurora" {
  description = "true → розгортає Aurora Cluster + writer instance; false → розгортає стандартну RDS instance"
  type        = bool
  default     = false
}

variable "engine" {
  description = "Тип двигуна БД: 'postgres' або 'mysql'"
  type        = string
  default     = "postgres"

  validation {
    condition     = contains(["postgres", "mysql"], var.engine)
    error_message = "Значення engine повинно бути 'postgres' або 'mysql'."
  }
}

variable "engine_version" {
  description = "Версія двигуна БД. Для PostgreSQL: '14.10', '15.4'; для MySQL: '8.0.35'"
  type        = string
  default     = "14.10"
}

variable "instance_class" {
  description = "Клас інстансу БД (наприклад: db.t3.medium, db.r6g.large)"
  type        = string
  default     = "db.t3.medium"
}

variable "vpc_id" {
  description = "ID VPC, в якій буде розгорнуто RDS"
  type        = string
}

variable "subnet_ids" {
  description = "Список ID підмереж для DB Subnet Group (рекомендується приватні підмережі)"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "CIDR-блоки, яким дозволено підключатися до БД (наприклад, CIDR VPC)"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "database_name" {
  description = "Назва початкової бази даних, яка створюється автоматично"
  type        = string
  default     = "appdb"
}

variable "master_username" {
  description = "Ім'я майстер-користувача БД"
  type        = string
  default     = "dbadmin"
}

variable "master_password" {
  description = "Пароль майстер-користувача БД (sensitive — не зберігається в state у відкритому вигляді)"
  type        = string
  sensitive   = true
}

variable "allocated_storage" {
  description = "Початковий розмір сховища в ГБ (тільки для стандартного RDS)"
  type        = number
  default     = 20
}

variable "max_allocated_storage" {
  description = "Максимальний розмір для автоскейлінгу сховища в ГБ (0 = вимкнено, тільки для стандартного RDS)"
  type        = number
  default     = 100
}

variable "storage_type" {
  description = "Тип сховища: gp2, gp3, io1 (тільки для стандартного RDS)"
  type        = string
  default     = "gp3"
}

variable "multi_az" {
  description = "Увімкнути Multi-AZ для стійкості до збоїв (тільки для стандартного RDS)"
  type        = bool
  default     = false
}

variable "aurora_instance_count" {
  description = "Кількість Aurora instances: 1 = лише writer; 2+ = writer + reader(s)"
  type        = number
  default     = 1
}

variable "storage_encrypted" {
  description = "Увімкнути шифрування сховища"
  type        = bool
  default     = true
}

variable "deletion_protection" {
  description = "Захист від випадкового видалення (рекомендується true для production)"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Пропустити фінальний snapshot при видаленні (false = зберегти snapshot)"
  type        = bool
  default     = true
}

variable "backup_retention_period" {
  description = "Кількість днів зберігання автоматичних backup (0 = вимкнено)"
  type        = number
  default     = 7
}

variable "parameter_group_family" {
  description = <<-EOT
    Сімейство parameter group. Якщо порожньо — обчислюється автоматично з engine+engine_version.
    Приклади: postgres14, aurora-postgresql14, mysql8.0, aurora-mysql8.0
  EOT
  type    = string
  default = ""
}

variable "db_parameters" {
  description = <<-EOT
    Список параметрів для DB Parameter Group.
    Значення за замовчуванням — PostgreSQL параметри.
    Для MySQL замініть на: max_connections, slow_query_log, long_query_time тощо.
  EOT
  type = list(object({
    name         = string
    value        = string
    apply_method = string
  }))
  default = [
    {
      name         = "max_connections"
      value        = "200"
      apply_method = "pending-reboot"
    },
    {
      name         = "log_statement"
      value        = "ddl"
      apply_method = "immediate"
    },
    {
      name         = "work_mem"
      value        = "65536"
      apply_method = "immediate"
    },
  ]
}

variable "tags" {
  description = "Теги, які застосовуються до всіх ресурсів модуля"
  type        = map(string)
  default     = {}
}

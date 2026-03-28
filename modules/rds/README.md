# Модуль `rds`

Універсальний Terraform-модуль для розгортання реляційної бази даних на AWS.
Підтримує два режими через одну змінну `use_aurora`:

| `use_aurora` | Що створюється |
|---|---|
| `false` (default) | `aws_db_instance` — стандартний RDS instance |
| `true` | `aws_rds_cluster` + `aws_rds_cluster_instance` — Aurora Cluster |

В обох режимах **автоматично** створюються:
- **DB Subnet Group** — групує приватні підмережі
- **Security Group** — дозволяє підключення до порту БД із зазначених CIDR
- **Parameter Group** — з параметрами `max_connections`, `log_statement`, `work_mem`

---

## Приклади використання

### Стандартний RDS (PostgreSQL 14)

```hcl
module "rds" {
  source = "./modules/rds"

  identifier  = "my-django-db"
  use_aurora  = false

  engine         = "postgres"
  engine_version = "14.10"
  instance_class = "db.t3.medium"

  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  allowed_cidr_blocks = ["10.0.0.0/16"]

  database_name   = "djangodb"
  master_username = "dbadmin"
  master_password = var.db_password

  allocated_storage = 20
  storage_type      = "gp3"
  multi_az          = false

  tags = {
    Environment = "dev"
  }
}
```

### Aurora PostgreSQL Cluster (2 інстанси: 1 writer + 1 reader)

```hcl
module "rds" {
  source = "./modules/rds"

  identifier  = "my-aurora-db"
  use_aurora  = true   # ← вмикає Aurora режим

  engine         = "postgres"
  engine_version = "14.10"
  instance_class = "db.r6g.large"  # Aurora рекомендує r6g/r7g

  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  allowed_cidr_blocks = ["10.0.0.0/16"]

  database_name   = "djangodb"
  master_username = "dbadmin"
  master_password = var.db_password

  aurora_instance_count = 2  # writer + 1 reader

  deletion_protection = true  # для production

  tags = {
    Environment = "production"
  }
}
```

### Aurora MySQL 8.0

```hcl
module "rds" {
  source = "./modules/rds"

  identifier  = "my-mysql-aurora"
  use_aurora  = true

  engine         = "mysql"
  engine_version = "8.0.32"
  instance_class = "db.r6g.large"

  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  allowed_cidr_blocks = ["10.0.0.0/16"]

  database_name   = "myapp"
  master_username = "admin"
  master_password = var.db_password

  aurora_instance_count = 1

  # Для MySQL потрібно передати MySQL-сумісні параметри
  db_parameters = [
    {
      name         = "max_connections"
      value        = "300"
      apply_method = "immediate"
    },
    {
      name         = "slow_query_log"
      value        = "1"
      apply_method = "immediate"
    },
    {
      name         = "long_query_time"
      value        = "2"
      apply_method = "immediate"
    },
  ]

  tags = {
    Environment = "staging"
  }
}
```

### Стандартний RDS з Multi-AZ та великим сховищем

```hcl
module "rds" {
  source = "./modules/rds"

  identifier  = "prod-rds"
  use_aurora  = false

  engine         = "postgres"
  engine_version = "15.4"
  instance_class = "db.r6g.large"

  vpc_id              = module.vpc.vpc_id
  subnet_ids          = module.vpc.private_subnets
  allowed_cidr_blocks = ["10.0.0.0/16"]

  database_name   = "proddb"
  master_username = "dbadmin"
  master_password = var.db_password

  allocated_storage     = 100
  max_allocated_storage = 500   # autoscaling up to 500 GB
  storage_type          = "gp3"
  multi_az              = true  # ← Multi-AZ для failover

  deletion_protection     = true
  skip_final_snapshot     = false  # зберегти snapshot при видаленні
  backup_retention_period = 14

  tags = {
    Environment = "production"
    Team        = "backend"
  }
}
```

---

## Отримання outputs у кореневому main.tf

```hcl
output "db_endpoint" {
  value = module.rds.endpoint
}

output "db_connection_string" {
  value = module.rds.connection_string
}
```

### Передача DATABASE_URL у Django ConfigMap (charts/django-app/values.yaml)

```yaml
config:
  env:
    DATABASE_URL: "postgresql://dbadmin:password@<endpoint>:5432/djangodb"
```

---

## Опис змінних

### Обов'язкові змінні

| Змінна | Тип | Опис |
|--------|-----|------|
| `identifier` | `string` | Унікальний ідентифікатор — використовується в назвах усіх ресурсів |
| `vpc_id` | `string` | ID VPC для розгортання RDS |
| `subnet_ids` | `list(string)` | Список ID приватних підмереж для DB Subnet Group |
| `master_password` | `string` (sensitive) | Пароль майстер-користувача |

### Ключова змінна: режим роботи

| Змінна | Тип | Default | Опис |
|--------|-----|---------|------|
| `use_aurora` | `bool` | `false` | `true` → Aurora Cluster; `false` → стандартний RDS |

### Engine та версія

| Змінна | Тип | Default | Опис |
|--------|-----|---------|------|
| `engine` | `string` | `"postgres"` | Тип двигуна: `"postgres"` або `"mysql"` |
| `engine_version` | `string` | `"14.10"` | Версія двигуна (напр., `"14.10"`, `"15.4"`, `"8.0.35"`) |
| `instance_class` | `string` | `"db.t3.medium"` | Клас інстансу (напр., `db.t3.medium`, `db.r6g.large`) |

### Мережа та безпека

| Змінна | Тип | Default | Опис |
|--------|-----|---------|------|
| `allowed_cidr_blocks` | `list(string)` | `["10.0.0.0/16"]` | CIDR-блоки, яким дозволено підключатися до порту БД |

### Конфігурація БД

| Змінна | Тип | Default | Опис |
|--------|-----|---------|------|
| `database_name` | `string` | `"appdb"` | Назва початкової бази даних |
| `master_username` | `string` | `"dbadmin"` | Ім'я майстер-користувача |

### Тільки для стандартного RDS (`use_aurora = false`)

| Змінна | Тип | Default | Опис |
|--------|-----|---------|------|
| `allocated_storage` | `number` | `20` | Початковий розмір сховища (ГБ) |
| `max_allocated_storage` | `number` | `100` | Максимум для autoscaling (`0` = вимкнено) |
| `storage_type` | `string` | `"gp3"` | Тип сховища: `gp2`, `gp3`, `io1` |
| `multi_az` | `bool` | `false` | Увімкнути Multi-AZ failover |

### Тільки для Aurora (`use_aurora = true`)

| Змінна | Тип | Default | Опис |
|--------|-----|---------|------|
| `aurora_instance_count` | `number` | `1` | Кількість instances: `1` = writer only; `2+` = writer + readers |

### Загальні налаштування

| Змінна | Тип | Default | Опис |
|--------|-----|---------|------|
| `storage_encrypted` | `bool` | `true` | Шифрування сховища |
| `deletion_protection` | `bool` | `false` | Захист від видалення (рекомендується `true` для prod) |
| `skip_final_snapshot` | `bool` | `true` | Пропустити final snapshot (`false` = зберегти backup) |
| `backup_retention_period` | `number` | `7` | Дні зберігання автобекапів (`0` = вимкнено) |
| `tags` | `map(string)` | `{}` | Теги для всіх ресурсів |

### Parameter Group

| Змінна | Тип | Default | Опис |
|--------|-----|---------|------|
| `parameter_group_family` | `string` | `""` | Явне сімейство PG (авто: `postgres14`, `aurora-postgresql14` і т.д.) |
| `db_parameters` | `list(object)` | PostgreSQL defaults | Список параметрів з `name`, `value`, `apply_method` |

---

## Outputs модуля

| Output | Опис |
|--------|------|
| `endpoint` | Основний endpoint підключення (writer для Aurora) |
| `port` | Порт БД (5432 / 3306) |
| `database_name` | Назва бази даних |
| `connection_string` | DATABASE_URL (пароль прихований) |
| `rds_endpoint` | Повний endpoint RDS (host:port), `null` для Aurora |
| `rds_address` | Hostname RDS, `null` для Aurora |
| `aurora_cluster_endpoint` | Writer endpoint Aurora, `null` для RDS |
| `aurora_reader_endpoint` | Reader endpoint Aurora, `null` для RDS |
| `aurora_instance_ids` | Список ID Aurora instances |
| `security_group_id` | ID Security Group |
| `subnet_group_name` | Назва DB Subnet Group |
| `parameter_group_name` | Назва активного Parameter Group |

---

## Як змінити тип БД, engine та клас інстансу

### Зміна engine та версії

```hcl
# PostgreSQL 15
engine         = "postgres"
engine_version = "15.4"

# MySQL 8.0
engine         = "mysql"
engine_version = "8.0.35"
```

> ⚠️ При зміні `engine` також оновіть `db_parameters` на сумісні з новим двигуном.

### Зміна класу інстансу

```hcl
# Dev/Test (дешевший)
instance_class = "db.t3.micro"

# Staging (збалансований)
instance_class = "db.t3.medium"

# Production RDS
instance_class = "db.r6g.large"

# Production Aurora (пам'ять-оптимізований)
instance_class = "db.r6g.xlarge"
```

### Перехід зі стандартного RDS на Aurora

```hcl
# Крок 1: Змінити use_aurora = true
use_aurora = true

# Крок 2: Змінити instance_class (Aurora не підтримує db.t3.*)
instance_class = "db.r6g.large"

# Крок 3: Видалити RDS-специфічні параметри (необов'язково, вони будуть проігноровані)
# allocated_storage, storage_type, multi_az

# Крок 4: Оновити db_parameters якщо потрібно
```

> ⚠️ Terraform видалить старий RDS і створить Aurora кластер.
> Зробіть ручний snapshot бази перед цим!

### Явне задання parameter group family

```hcl
# Якщо автообчислення не підходить
parameter_group_family = "aurora-postgresql14"
```

### Вимкнення parameter group параметрів

```hcl
# Пустий список = parameter group без параметрів
db_parameters = []
```

---

## Автоматичне обчислення parameter group family

Модуль автоматично обчислює `parameter_group_family` з `engine` + `engine_version`:

| engine | engine_version | use_aurora | Результат |
|--------|---------------|-----------|-----------|
| `postgres` | `14.10` | `false` | `postgres14` |
| `postgres` | `14.10` | `true` | `aurora-postgresql14` |
| `postgres` | `15.4` | `false` | `postgres15` |
| `mysql` | `8.0.35` | `false` | `mysql8.0` |
| `mysql` | `8.0.32` | `true` | `aurora-mysql8.0` |

---

## Розгортання

```bash
# Перша ініціалізація
terraform init

# Перегляд плану
terraform plan -var="db_password=MySecret123"

# Застосування
terraform apply -var="db_password=MySecret123"

# Отримання endpoint
terraform output rds_endpoint
terraform output rds_connection_string
```

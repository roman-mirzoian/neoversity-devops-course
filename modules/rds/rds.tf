resource "aws_db_instance" "this" {
  count = var.use_aurora ? 0 : 1

  identifier     = var.identifier
  engine         = var.engine         # "postgres" або "mysql"
  engine_version = var.engine_version # "14.10", "8.0.35" тощо

  instance_class = var.instance_class # db.t3.medium, db.r6g.large тощо
  multi_az       = var.multi_az       # false = single-AZ, true = Multi-AZ failover

  # Сховище
  allocated_storage     = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage > 0 ? var.max_allocated_storage : null
  storage_type          = var.storage_type
  storage_encrypted     = var.storage_encrypted

  # Дані для підключення
  db_name  = var.database_name
  username = var.master_username
  password = var.master_password

  # Мережа та безпека
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = [aws_security_group.this.id]
  parameter_group_name   = aws_db_parameter_group.rds[0].name
  publicly_accessible    = false

  # Backup та захист від видалення
  backup_retention_period   = var.backup_retention_period
  deletion_protection       = var.deletion_protection
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-snapshot"

  tags = local.common_tags
}

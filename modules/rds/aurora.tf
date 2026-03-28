resource "aws_rds_cluster" "this" {
  count = var.use_aurora ? 1 : 0

  cluster_identifier = var.identifier
  engine             = local.aurora_engine  # aurora-postgresql або aurora-mysql
  engine_version     = var.engine_version   # наприклад, "14.10" або "8.0.32"

  # Дані для підключення
  database_name   = var.database_name
  master_username = var.master_username
  master_password = var.master_password

  # Мережа та безпека
  db_subnet_group_name            = aws_db_subnet_group.this.name
  vpc_security_group_ids          = [aws_security_group.this.id]
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.aurora[0].name

  # Шифрування та захист
  storage_encrypted   = var.storage_encrypted
  deletion_protection = var.deletion_protection

  # Backup
  backup_retention_period   = var.backup_retention_period
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.identifier}-final-snapshot"

  tags = local.common_tags
}

resource "aws_rds_cluster_instance" "this" {
  count = var.use_aurora ? var.aurora_instance_count : 0

  identifier         = "${var.identifier}-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.this[0].id
  engine             = aws_rds_cluster.this[0].engine
  engine_version     = aws_rds_cluster.this[0].engine_version
  instance_class     = var.instance_class

  db_subnet_group_name    = aws_db_subnet_group.this.name
  db_parameter_group_name = aws_db_parameter_group.aurora_instance[0].name
  publicly_accessible     = false

  tags = merge(local.common_tags, {
    Name = "${var.identifier}-instance-${count.index + 1}"
    Role = count.index == 0 ? "writer" : "reader"
  })
}

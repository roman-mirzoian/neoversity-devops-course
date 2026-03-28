locals {
  major_version = split(".", var.engine_version)[0]
  minor_version = length(split(".", var.engine_version)) > 1 ? split(".", var.engine_version)[1] : "0"

  aurora_engine = var.engine == "postgres" ? "aurora-postgresql" : "aurora-mysql"

  computed_pg_family = (
    var.use_aurora && var.engine == "postgres"  ? "aurora-postgresql${local.major_version}" :
    var.use_aurora && var.engine == "mysql"     ? "aurora-mysql${local.major_version}.${local.minor_version}" :
    !var.use_aurora && var.engine == "postgres" ? "postgres${local.major_version}" :
    "mysql${local.major_version}.${local.minor_version}"
  )

  parameter_group_family = var.parameter_group_family != "" ? var.parameter_group_family : local.computed_pg_family

  db_port = var.engine == "postgres" ? 5432 : 3306

  common_tags = merge(var.tags, {
    Name       = var.identifier
    Engine     = var.engine
    UseAurora  = tostring(var.use_aurora)
    ManagedBy  = "terraform"
  })
}

resource "aws_db_subnet_group" "this" {
  name        = "${var.identifier}-subnet-group"
  description = "Subnet group for ${var.identifier} (${var.engine})"
  subnet_ids  = var.subnet_ids

  tags = local.common_tags
}

resource "aws_security_group" "this" {
  name        = "${var.identifier}-sg"
  description = "Security group for ${var.identifier} RDS (port ${local.db_port})"
  vpc_id      = var.vpc_id

  ingress {
    description = "DB connections from allowed CIDRs"
    from_port   = local.db_port
    to_port     = local.db_port
    protocol    = "tcp"
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_db_parameter_group" "rds" {
  count = var.use_aurora ? 0 : 1

  name        = "${var.identifier}-pg"
  family      = local.parameter_group_family
  description = "Parameter group for ${var.identifier} (${local.parameter_group_family})"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_rds_cluster_parameter_group" "aurora" {
  count = var.use_aurora ? 1 : 0

  name        = "${var.identifier}-cluster-pg"
  family      = local.parameter_group_family
  description = "Cluster parameter group for ${var.identifier} Aurora (${local.parameter_group_family})"

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_parameter_group" "aurora_instance" {
  count = var.use_aurora ? 1 : 0

  name        = "${var.identifier}-instance-pg"
  family      = local.parameter_group_family
  description = "Instance parameter group for ${var.identifier} Aurora instances (${local.parameter_group_family})"

  dynamic "parameter" {
    for_each = var.db_parameters
    content {
      name         = parameter.value.name
      value        = parameter.value.value
      apply_method = parameter.value.apply_method
    }
  }

  tags = local.common_tags

  lifecycle {
    create_before_destroy = true
  }
}

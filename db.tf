resource "aws_db_subnet_group" "db" {
  count      = var.db_subnet_group_name == "" ? 1 : 0
  name       = "wordpress_db_subnet_group"
  subnet_ids = var.db_subnet_group_subnet_ids
  tags       = var.tags
}

resource "aws_rds_cluster" "wordpress" {
  cluster_identifier      = var.rds_cluster_identifier
  backup_retention_period = var.rds_cluster_backup_retention_period
  copy_tags_to_snapshot   = true
  database_name           = var.rds_cluster_database_name
  db_subnet_group_name    = local.db_subnet_group_name
  deletion_protection     = var.rds_cluster_deletion_protection
  #  enabled_cloudwatch_logs_exports = var.rds_cluster_enable_cloudwatch_logs_export
  #  engine_version                  = local.rds_cluster_engine_version
  engine      = "aurora-mysql"
  engine_mode = "serverless"
  scaling_configuration {
    auto_pause               = true
    max_capacity             = 4
    min_capacity             = 2
    seconds_until_auto_pause = 300
    timeout_action           = "ForceApplyCapacityChange"
  }
  final_snapshot_identifier    = var.rds_cluster_identifier
  kms_key_id                   = aws_kms_key.wordpress.arn
  master_password              = random_password.db_password.result
  master_username              = var.rds_cluster_master_username
  preferred_backup_window      = var.rds_cluster_preferred_backup_window
  preferred_maintenance_window = var.rds_cluster_preferred_maintenance_window
  storage_encrypted            = true
  skip_final_snapshot          = var.rds_cluster_skip_final_snapshot
  vpc_security_group_ids       = local.rds_cluster_security_group_ids
  tags                         = var.tags
}

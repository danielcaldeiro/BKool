resource "random_password" "db_password" {
  length  = 16
  special = false
}

resource "aws_kms_key" "wordpress" {
  description             = "KMS Key used to encrypt Wordpress related resources"
  deletion_window_in_days = 7
  enable_key_rotation     = true
  policy                  = data.aws_iam_policy_document.kms.json
  tags                    = var.tags
}

resource "aws_kms_alias" "wordpress" {
  name          = "alias/wordpress"
  target_key_id = aws_kms_key.wordpress.id
}

resource "aws_cloudwatch_log_group" "wordpress" {
  name              = var.ecs_cloudwatch_logs_group_name
  retention_in_days = 14
  kms_key_id        = aws_kms_key.wordpress.arn
  tags              = var.tags
}

resource "aws_secretsmanager_secret" "wordpress" {
  name_prefix = var.secrets_manager_name
  description = "Secrets for ECS Wordpress"
  kms_key_id  = aws_kms_key.wordpress.id
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "wordpress" {
  secret_id = aws_secretsmanager_secret.wordpress.id
  secret_string = jsonencode({
    WORDPRESS_DB_HOST     = aws_rds_cluster.wordpress.endpoint
    WORDPRESS_DB_USER     = var.rds_cluster_master_username
    WORDPRESS_DB_PASSWORD = random_password.db_password.result
    WORDPRESS_DB_NAME     = var.rds_cluster_database_name
  })
}

resource "aws_vpc_endpoint" "ssm" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.us-east-1.ssmmessages"
  vpc_endpoint_type   = "Interface"
  security_group_ids  = local.ecs_service_security_group_ids
  subnet_ids          = var.ecs_service_subnet_ids
  private_dns_enabled = true
}

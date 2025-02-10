resource "aws_ecs_cluster" "wordpress" {
  name               = var.ecs_cluster_name
  tags               = var.tags
  capacity_providers = ["FARGATE", "FARGATE_SPOT"]
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 50
  }
  default_capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 50
    base              = "1"
  }
  configuration {
    execute_command_configuration {
      kms_key_id = aws_kms_key.wordpress.arn
      logging    = "OVERRIDE"

      log_configuration {
        cloud_watch_encryption_enabled = true
        cloud_watch_log_group_name     = var.ecs_cloudwatch_logs_group_name
      }
    }
  }
}

resource "aws_ecs_task_definition" "wordpress" {
  family = var.ecs_task_definition_family
  container_definitions = templatefile(
    "${path.module}/wordpress.tpl",
    {
      ecs_service_container_name = var.ecs_service_container_name
      wordpress_db_host          = aws_rds_cluster.wordpress.endpoint
      wordpress_db_user          = var.rds_cluster_master_username
      wordpress_db_name          = var.rds_cluster_database_name
      aws_region                 = data.aws_region.current.name
      aws_logs_group             = aws_cloudwatch_log_group.wordpress.name
      aws_account_id             = data.aws_caller_identity.current.account_id
      secret_name                = aws_secretsmanager_secret.wordpress.name
      cloudwatch_log_group       = var.ecs_cloudwatch_logs_group_name
    }
  )
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.ecs_task_definition_cpu
  memory                   = var.ecs_task_definition_memory
  execution_role_arn       = aws_iam_role.ecs_task_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  volume {
    name = "efs-themes"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.wordpress.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.wordpress_themes.id
      }
    }
  }
  volume {
    name = "efs-plugins"
    efs_volume_configuration {
      file_system_id     = aws_efs_file_system.wordpress.id
      root_directory     = "/"
      transit_encryption = "ENABLED"
      authorization_config {
        access_point_id = aws_efs_access_point.wordpress_plugins.id
      }
    }
  }
  tags = var.tags
}

resource "aws_ecs_service" "wordpress" {
  name            = var.ecs_service_name
  cluster         = aws_ecs_cluster.wordpress.arn
  task_definition = aws_ecs_task_definition.wordpress.arn
  desired_count   = var.ecs_service_desired_count
  #launch_type            = "FARGATE"
  platform_version       = "1.4.0"
  propagate_tags         = "SERVICE"
  enable_execute_command = true
  capacity_provider_strategy {
    capacity_provider = "FARGATE_SPOT"
    weight            = 50
  }
  capacity_provider_strategy {
    capacity_provider = "FARGATE"
    weight            = 50
  }
  network_configuration {
    subnets          = var.ecs_service_subnet_ids
    security_groups  = local.ecs_service_security_group_ids
    assign_public_ip = var.ecs_service_assign_public_ip
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.wordpress_http.arn
    container_name   = var.ecs_service_container_name
    container_port   = "80"
  }
  tags = var.tags
}

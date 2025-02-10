resource "aws_efs_file_system" "wordpress" {
  creation_token = "wordpress"
  encrypted      = true
  kms_key_id     = aws_kms_key.wordpress.arn
  tags           = var.tags
}

resource "aws_efs_mount_target" "wordpress" {
  count           = length(var.ecs_service_subnet_ids)
  file_system_id  = aws_efs_file_system.wordpress.id
  subnet_id       = var.ecs_service_subnet_ids[count.index]
  security_groups = local.efs_service_security_group_ids
}

resource "aws_efs_access_point" "wordpress_plugins" {
  file_system_id = aws_efs_file_system.wordpress.id
  posix_user {
    gid = 33
    uid = 33
  }
  root_directory {
    path = "/plugins"
    creation_info {
      owner_gid   = 33
      owner_uid   = 33
      permissions = 755
    }
  }
}

resource "aws_efs_access_point" "wordpress_themes" {
  file_system_id = aws_efs_file_system.wordpress.id
  posix_user {
    gid = 33
    uid = 33
  }
  root_directory {
    path = "/themes"
    creation_info {
      owner_gid   = 33
      owner_uid   = 33
      permissions = 755
    }
  }
}

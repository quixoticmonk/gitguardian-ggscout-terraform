# Store GitGuardian API key in Secrets Manager
resource "aws_secretsmanager_secret" "gitguardian_api_key" {
  name                    = "ggscout/gitguardian-api-key-${random_id.secret_suffix.hex}"
  description             = "GitGuardian API key for ggscout"
  recovery_window_in_days = 0
  tags                    = local.common_tags
}

resource "random_id" "secret_suffix" {
  byte_length = 4
}

resource "aws_secretsmanager_secret_version" "gitguardian_api_key" {
  secret_id     = aws_secretsmanager_secret.gitguardian_api_key.id
  secret_string = var.gitguardian_api_key
}

# VPC and Networking
resource "aws_vpc" "ggscout" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = merge(local.common_tags, {
    Name = "ggscout-vpc"
  })
}

resource "aws_internet_gateway" "ggscout" {
  vpc_id = aws_vpc.ggscout.id
  tags = merge(local.common_tags, {
    Name = "ggscout-igw"
  })
}

resource "aws_subnet" "private" {
  count             = 2
  vpc_id            = aws_vpc.ggscout.id
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = merge(local.common_tags, {
    Name = "ggscout-private-${count.index + 1}"
  })
}

resource "aws_subnet" "public" {
  count                   = 2
  vpc_id                  = aws_vpc.ggscout.id
  cidr_block              = "10.0.${count.index + 10}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = merge(local.common_tags, {
    Name = "ggscout-public-${count.index + 1}"
  })
}

resource "aws_eip" "nat" {
  count  = 2
  domain = "vpc"
  tags = merge(local.common_tags, {
    Name = "ggscout-nat-${count.index + 1}"
  })
}

resource "aws_nat_gateway" "ggscout" {
  count         = 2
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  tags = merge(local.common_tags, {
    Name = "ggscout-nat-${count.index + 1}"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.ggscout.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.ggscout.id
  }
  tags = merge(local.common_tags, {
    Name = "ggscout-public-rt"
  })
}

resource "aws_route_table" "private" {
  count  = 2
  vpc_id = aws_vpc.ggscout.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ggscout[count.index].id
  }
  tags = merge(local.common_tags, {
    Name = "ggscout-private-rt-${count.index + 1}"
  })
}

resource "aws_route_table_association" "public" {
  count          = 2
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Security Group for ECS Tasks
resource "aws_security_group" "ggscout" {
  name_prefix = "ggscout-"
  vpc_id      = aws_vpc.ggscout.id
  description = "Security group for ggscout ECS tasks"

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "HTTPS outbound for GitGuardian API"
  }

  egress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.ggscout.cidr_block]
    description = "EFS access"
  }

  tags = merge(local.common_tags, {
    Name = "ggscout-sg"
  })
}

# ECS Cluster
resource "aws_ecs_cluster" "ggscout" {
  name = "ggscout-cluster"
  tags = local.common_tags

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_execution_role" {
  name = "ggscout-execution-role"
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Additional policy for Secrets Manager access
resource "aws_iam_role_policy" "ecs_execution_secrets_policy" {
  name = "ggscout-execution-secrets-policy"
  role = aws_iam_role.ecs_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.gitguardian_api_key.arn
      }
    ]
  })
}

# IAM Role for ggscout Task
resource "aws_iam_role" "ggscout_task_role" {
  name = "ggscout-task-role"
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy for Secrets Manager Access (scoped to specific secret)
resource "aws_iam_role_policy" "ggscout_secrets_policy" {
  name = "ggscout-secrets-policy"
  role = aws_iam_role.ggscout_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = aws_secretsmanager_secret.gitguardian_api_key.arn
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:ListSecrets",
          "secretsmanager:BatchGetSecretValue",
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetSecretValue",
          "secretsmanager:ListSecretVersionIds"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })
}

# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ggscout" {
  name              = "/ecs/ggscout"
  retention_in_days = 7
  tags              = local.common_tags
}

# EFS for config file storage
resource "aws_efs_file_system" "ggscout_config" {
  creation_token = "ggscout-config"

  tags = merge(local.common_tags, {
    Name = "ggscout-config"
  })
}

resource "aws_efs_mount_target" "ggscout_config" {
  count           = length(aws_subnet.private)
  file_system_id  = aws_efs_file_system.ggscout_config.id
  subnet_id       = aws_subnet.private[count.index].id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_security_group" "efs" {
  name_prefix = "ggscout-efs-"
  vpc_id      = aws_vpc.ggscout.id

  ingress {
    from_port       = 2049
    to_port         = 2049
    protocol        = "tcp"
    security_groups = [aws_security_group.ggscout.id]
  }

  tags = merge(local.common_tags, {
    Name = "ggscout-efs-sg"
  })
}

# ECS Task Definition
resource "aws_ecs_task_definition" "ggscout" {
  family                   = "ggscout"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ggscout_task_role.arn
  tags                     = local.common_tags

  volume {
    name = "ggscout-config"

    efs_volume_configuration {
      file_system_id = aws_efs_file_system.ggscout_config.id
      root_directory = "/"
    }
  }

  container_definitions = jsonencode([
    {
      name      = "config-init"
      image     = "alpine:latest"
      essential = false

      command = [
        "sh", "-c",
        "cat > /config/ggscout.toml << 'EOF'\n[gitguardian]\napi_token = \"$${GITGUARDIAN_API_KEY}\"\nendpoint = \"$${GITGUARDIAN_API_URL}\"\n\n[sources.aws-secrets]\ntype = \"awssecretsmanager\"\nfetch_all_versions = true\nregions = ${jsonencode(var.scan_regions)}\nmode = \"read\"\nenv = \"${var.environment}\"\nowner = \"${var.owner_email}\"\n\n[[sources.aws-secrets.include]]\nresource_ids = [\"*\"]\nEOF"
      ]

      mountPoints = [
        {
          sourceVolume  = "ggscout-config"
          containerPath = "/config"
          readOnly      = false
        }
      ]

      secrets = [
        {
          name      = "GITGUARDIAN_API_KEY"
          valueFrom = aws_secretsmanager_secret.gitguardian_api_key.arn
        }
      ]

      environment = [
        {
          name  = "GITGUARDIAN_API_URL"
          value = "https://api.gitguardian.com/v1"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ggscout.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "init"
        }
      }
    },
    {
      name      = "ggscout"
      image     = "ghcr.io/gitguardian/ggscout/chainguard:${var.ggscout_image_tag}"
      essential = true

      dependsOn = [
        {
          containerName = "config-init"
          condition     = "SUCCESS"
        }
      ]

      command = ["fetch-and-send", "/config/ggscout.toml"]

      secrets = [
        {
          name      = "GITGUARDIAN_API_KEY"
          valueFrom = aws_secretsmanager_secret.gitguardian_api_key.arn
        }
      ]

      environment = [
        {
          name  = "GITGUARDIAN_API_URL"
          value = "https://api.gitguardian.com/v1"
        }
      ]

      mountPoints = [
        {
          sourceVolume  = "ggscout-config"
          containerPath = "/config"
          readOnly      = true
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ggscout.name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "ecs"
        }
      }

      # Security settings
      readonlyRootFilesystem = true
      user                   = "65532:65532" # nonroot user
    }
  ])
}

# EventBridge Rule for Scheduling
resource "aws_cloudwatch_event_rule" "ggscout_schedule" {
  name                = "ggscout-schedule"
  description         = "Schedule for ggscout execution"
  schedule_expression = var.schedule_expression
  tags                = local.common_tags
}

# IAM Role for EventBridge
resource "aws_iam_role" "eventbridge_role" {
  name = "ggscout-eventbridge-role"
  tags = local.common_tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "events.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "eventbridge_ecs_policy" {
  name = "ggscout-eventbridge-ecs-policy"
  role = aws_iam_role.eventbridge_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:RunTask"
        ]
        Resource = aws_ecs_task_definition.ggscout.arn
      },
      {
        Effect = "Allow"
        Action = [
          "iam:PassRole"
        ]
        Resource = [
          aws_iam_role.ecs_execution_role.arn,
          aws_iam_role.ggscout_task_role.arn
        ]
      }
    ]
  })
}

# EventBridge Target
resource "aws_cloudwatch_event_target" "ggscout_target" {
  rule      = aws_cloudwatch_event_rule.ggscout_schedule.name
  target_id = "ggscout-target"
  arn       = aws_ecs_cluster.ggscout.arn
  role_arn  = aws_iam_role.eventbridge_role.arn

  ecs_target {
    task_count          = 1
    task_definition_arn = aws_ecs_task_definition.ggscout.arn
    launch_type         = "FARGATE"
    platform_version    = "LATEST"

    network_configuration {
      subnets         = aws_subnet.private[*].id
      security_groups = [aws_security_group.ggscout.id]
    }
  }
}

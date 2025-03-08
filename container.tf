
resource "aws_ecs_cluster" "main" {
  provider = aws.tokyo
  name     = "reservation-cluster"
}

resource "aws_ecs_task_definition" "api" {
  provider                 = aws.tokyo
  family                   = "cloudtech-reservation-api-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "reservation-api-container"
      image     = "public.ecr.aws/z7i1h7x3/cloudtech-reservation-api:latest"
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
          appProtocol   = "http"
        }
      ]
      environment = [
        {
          name  = "API_PORT"
          value = "80"
        },
        {
          name  = "DB_USERNAME"
          value = var.DatabaseUsername
        },
        {
          name  = "DB_PASSWORD"
          value = var.DatabasePassword
        },
        {
          name  = "DB_SERVERNAME"
          value = aws_db_instance.main.address
        },
        {
          name  = "DB_PORT"
          value = "3306"
        },
        {
          name  = "DB_NAME"
          value = var.DatabaseName
        }
      ]
    }
  ])
}

resource "aws_lb_target_group" "api" {
  provider    = aws.tokyo
  name        = "api-target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"
  
  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "api" {
  provider          = aws.tokyo
  load_balancer_arn = aws_lb.api.arn
  port              = 443
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = aws_acm_certificate.alb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

resource "aws_ecs_service" "api" {
  provider          = aws.tokyo
  name              = "reservation-service"
  cluster           = aws_ecs_cluster.main.id
  task_definition   = aws_ecs_task_definition.api.arn
  desired_count     = 2
  launch_type       = "FARGATE"
  platform_version  = "LATEST"
  
  network_configuration {
    subnets          = [aws_subnet.private_1.id, aws_subnet.private_2.id]
    security_groups  = [aws_security_group.api_server.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.api.arn
    container_name   = "reservation-api-container"
    container_port   = 80
  }

  depends_on = [aws_lb_listener.api]
}

# Auto Scaling
resource "aws_appautoscaling_target" "api" {
  provider           = aws.tokyo
  max_capacity       = 4
  min_capacity       = 2
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.api.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "api_cpu" {
  provider           = aws.tokyo
  name               = "CPUTargetTracking"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.api.resource_id
  scalable_dimension = aws_appautoscaling_target.api.scalable_dimension
  service_namespace  = aws_appautoscaling_target.api.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }
    target_value = 90.0
  }
}

resource "aws_iam_role" "autoscaling" {
  provider = aws.tokyo
  name     = "ecs-autoscaling-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "application-autoscaling.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "autoscaling" {
  provider   = aws.tokyo
  role       = aws_iam_role.autoscaling.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceAutoscaleRole"
}

resource "aws_lb" "api" {
  provider           = aws.tokyo
  name               = "api-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_1.id, aws_subnet.public_2.id]

  enable_deletion_protection = false

  tags = {
    Name = "api-alb"
  }
}

output "alb_dns_name" {
  value = aws_lb.api.dns_name
}

output "alb_zone_id" {
  value = aws_lb.api.zone_id
}

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.53.0"    //Tieni d'occhio la versione del template
    }
  }
}

data "aws_ami" "ecs_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-ecs-hvm-*-x86_64-ebs"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}

resource "aws_ecs_cluster" "main" {
  name = var.cluster_name
}

resource "aws_security_group" "ecs_sg" {
  name_prefix = "ecs-sg-"
  description = "ECS Security Group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "alb_sg" {
  name_prefix = "alb-sg-"
  description = "ALB Security Group"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/${var.cluster_name}"
  retention_in_days = 14
}

resource "aws_ecs_task_definition" "cars" {
  family                   = "cars-td"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "1024"

  container_definitions = jsonencode([
    {
      name      = "cars-microservice",
      image     = "platella/cars-microservice",
      essential = true,
      cpu       = 256,
      memory    = 1024,
      portMappings = [
        {
          containerPort = 8080,
          hostPort      = 8080
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
          "awslogs-region"        = var.aws_region,
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "bikes" {
  family                   = "bikes-td"
  network_mode             = "bridge"
  requires_compatibilities = ["EC2"]
  cpu                      = "256"
  memory                   = "1024"

  container_definitions = jsonencode([
    {
      name      = "bikes-microservice",
      image     = "platella/bikes-microservice",
      essential = true,
      cpu       = 256,
      memory    = 1024,
      portMappings = [
        {
          containerPort = 8080,
          hostPort      = 8080
        }
      ],
      logConfiguration = {
        logDriver = "awslogs",
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name,
          "awslogs-region"        = var.aws_region,
          "awslogs-stream-prefix" = "ecs"
        }
      }
    }
  ])
}

resource "aws_lb" "ecs_lb" {
  name               = "ecs-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = var.subnet_ids

  enable_deletion_protection = false
  idle_timeout               = 30
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.ecs_lb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Please go to /bikes or /cars"
      status_code  = "200"
    }
  }
}

resource "aws_lb_target_group" "cars_tg" {
  name     = "cars-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/cars"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_target_group" "bikes_tg" {
  name     = "bikes-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/bikes"
    interval            = 10
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener_rule" "cars_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 1

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.cars_tg.arn
  }

  condition {
    path_pattern {
      values = ["/cars"]
    }
  }
}

resource "aws_lb_listener_rule" "bikes_rule" {
  listener_arn = aws_lb_listener.http.arn
  priority     = 2

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.bikes_tg.arn
  }

  condition {
    path_pattern {
      values = ["/bikes"]
    }
  }
}

resource "aws_iam_role" "ecs_service_role" {
  name = "ecsServiceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action    = "sts:AssumeRole",
        Effect    = "Allow",
        Principal = {
          Service = "ecs.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_service_policy" {
  role       = aws_iam_role.ecs_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceRole"
}

resource "aws_autoscaling_group" "ecs_instances" {
  desired_capacity     = var.desired_capacity
  max_size             = var.max_size
  min_size             = var.desired_capacity
  vpc_zone_identifier  = var.subnet_ids
  launch_configuration = aws_launch_configuration.ecs_instance_lc.id
}

resource "aws_launch_configuration" "ecs_instance_lc" {
  name          = "ecs-instance-lc"
  image_id      = data.aws_ami.ecs_ami.image_id
  instance_type = var.instance_type
  key_name      = var.key_name
  security_groups = [
    aws_security_group.ecs_sg.id
  ]

  lifecycle {
    create_before_destroy = true
  }

  user_data = <<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
  EOF
}

resource "aws_ecs_service" "cars" {
  name            = "cars-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.cars.arn
  desired_count   = 1
  launch_type     = "EC2"

  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 50

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.cars_tg.arn
    container_name   = "cars-microservice"
    container_port   = 8080
  }
}

resource "aws_ecs_service" "bikes" {
  name            = "bikes-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.bikes.arn
  desired_count   = 1
  launch_type     = "EC2"

  deployment_maximum_percent = 200
  deployment_minimum_healthy_percent = 50

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.ecs_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.bikes_tg.arn
    container_name   = "bikes-microservice"
    container_port   = 8080
  }
}

resource "aws_cloudwatch_metric_alarm" "alb_500s_alarm" {
  alarm_name          = "ALB-5xx-Errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "HTTPCode_ELB_5XX_Count"
  namespace           = "AWS/ApplicationELB"
  period              = "60"
  statistic           = "Sum"
  threshold           = "5"

  dimensions = {
    LoadBalancer = aws_lb.ecs_lb.arn
  }

  alarm_actions = [
    "arn:aws:sns:us-east-1:123456789012:MySNSTopic"
  ]

  ok_actions = [
    "arn:aws:sns:us-east-1:123456789012:MySNSTopic"
  ]

  insufficient_data_actions = [
    "arn:aws:sns:us-east-1:123456789012:MySNSTopic"
  ]
}

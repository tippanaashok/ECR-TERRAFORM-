resource "aws_ecs_cluster" "web-cluster" {
  name = "new-cluster"
  #capacity_providers = [aws_ecs_capacity_provider.test.name]
  tags = {
    "env" = "dev"

  }
}
/*
resource "aws_ecs_capacity_provider" "test" {
  name = "capacity-provider-test"
  auto_scaling_group_provider {
    auto_scaling_group_arn         = aws_autoscaling_group.asg.arn
    managed_termination_protection = "ENABLED"

    managed_scaling {
      status          = "ENABLED"
      target_capacity = 85
    }
  }
}
*/


# update file container-def, so it's pulling image from ecr
resource "aws_ecs_task_definition" "task-definition-test" {
  family                = "web-family"
  network_mode          = "bridge"
  container_definitions = <<DEFINITION
[
  {
    "image": "nginx:latest",
    "cpu": 1024,
    "memory": 2048,
    "name": "hello-world-app",
    "networkMode": "awsvpc",
    "portMappings": [
      {
        "containerPort": 80,
        "hostPort": 80
      }
    ]
  }
]
DEFINITION
}




resource "aws_ecs_service" "service" {
  name            = "web-service"
  cluster         = aws_ecs_cluster.web-cluster.id
  task_definition = aws_ecs_task_definition.task-definition-test.arn
  desired_count   = 1
  #launch_type = "EC2"

  load_balancer {
    target_group_arn = aws_lb_target_group.lb_target_group.arn
    container_name   = "hello-world-app"
    container_port   = 80
  }
  # Optional: Allow external changes without Terraform plan difference(for example ASG)
  lifecycle {
    ignore_changes = [desired_count]
  }
  launch_type = "EC2"
  depends_on  = [aws_lb_listener.web-listener]
}

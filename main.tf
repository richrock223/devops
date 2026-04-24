terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "nlb_count" {
  description = "Number of NLBs to create"
  type        = number
  default     = 3
}

locals {
  common_tags = {
    Environment = "Dev"
    Project     = "Demo"
  }
}

# Fetch the default VPC
data "aws_vpc" "default" {
  filter {
    name   = "tag:Name"
    values = ["csr-vpc-dev-internal"]
  }
}

# Fetch all subnets in the default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Target Groups
resource "aws_lb_target_group" "nlb_tg" {
  count       = var.nlb_count
  name        = "nlb-public-${count.index + 1}-tg"
  port        = 80
  protocol    = "TCP"
  vpc_id      = data.aws_vpc.default.id
  target_type = "instance"

  health_check {
    enabled  = true
    protocol = "TCP"
    port     = "80"
  }

  tags = merge(local.common_tags, {
    Name = "nlb-public-${count.index + 1}-tg"
  })
}

# Network Load Balancers
resource "aws_lb" "nlb" {
  count              = var.nlb_count
  name               = "nlb-public-${count.index + 1}"
  internal           = true
  load_balancer_type = "network"
  subnets            = data.aws_subnets.default.ids

  enable_cross_zone_load_balancing = true

  tags = merge(local.common_tags, {
    Name = "nlb-public-${count.index + 1}"
  })
}

# Listeners
resource "aws_lb_listener" "nlb_listener" {
  count             = var.nlb_count
  load_balancer_arn = aws_lb.nlb[count.index].arn
  port              = 80
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.nlb_tg[count.index].arn
  }

  tags = merge(local.common_tags, {
    Name = "nlb-public-${count.index + 1}-listener"
  })
}

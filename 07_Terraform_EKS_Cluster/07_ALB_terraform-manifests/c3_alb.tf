# Security Group for Application Load Balancer
resource "aws_security_group" "alb" {
  name_prefix = "retail-store-alb-sg-"
  description = "Security group for Application Load Balancer"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name        = "retail-store-alb-sg"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

# Allow HTTP (80) from anywhere
resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
  description       = "Allow HTTP from anywhere"
}

# Allow HTTPS (443) from anywhere
resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
  description       = "Allow HTTPS from anywhere"
}

# Allow all outbound traffic
resource "aws_vpc_security_group_egress_rule" "alb_all" {
  security_group_id = aws_security_group.alb.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound traffic"
}

# Application Load Balancer
resource "aws_lb" "retail_store" {
  name               = "retail-store-alb-${var.environment}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = data.terraform_remote_state.vpc.outputs.public_subnet_ids

  enable_deletion_protection = false
  enable_http2              = true

  tags = {
    Name        = "retail-store-alb"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

# Target Group for UI Service
resource "aws_lb_target_group" "ui" {
  name        = "retail-store-ui-tg-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "retail-store-ui-tg"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

# Target Group for API Services
resource "aws_lb_target_group" "api" {
  name        = "retail-store-api-tg-${var.environment}"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id
  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/health"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "retail-store-api-tg"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

# HTTP Listener (Redirects to HTTPS if certificate is provided, otherwise forwards)
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.retail_store.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = var.certificate_arn != null ? "redirect" : "forward"

    dynamic "redirect" {
      for_each = var.certificate_arn != null ? [1] : []
      content {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }

    dynamic "forward" {
      for_each = var.certificate_arn == null ? [1] : []
      content {
        target_group {
          arn = aws_lb_target_group.ui.arn
        }
      }
    }
  }
}

# HTTPS Listener (Only created if certificate is provided)
resource "aws_lb_listener" "https" {
  count             = var.certificate_arn != null ? 1 : 0
  load_balancer_arn = aws_lb.retail_store.arn
  port              = 443
  protocol          = "HTTPS"
  certificate_arn   = var.certificate_arn

  default_action {
    type = "forward"
    forward {
      target_group {
        arn = aws_lb_target_group.ui.arn
      }
    }
  }

  tags = {
    Name        = "retail-store-alb-https-listener"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

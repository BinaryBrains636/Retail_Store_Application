resource "aws_security_group" "redis_sg" {
  name        = "${local.name}-redis-sg"
  description = "Allow EKS cluster to access ElastiCache Redis"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    from_port                = 6379
    to_port                  = 6379
    protocol                 = "tcp"
    cidr_blocks              = [data.terraform_remote_state.vpc.outputs.vpc_cidr]
    description              = "Allow traffic from EKS VPC"
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${local.name}-redis-sg" }
}

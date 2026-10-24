# Security Group for RDS PostgreSQL
# Allow access only from EKS Cluster security group
resource "aws_security_group" "rds_postgresql_sg" {
  name        = "${local.name}-rds-postgresql-sg"
  description = "Allow RDS PostgreSQL access from EKS cluster"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  ingress {
    description      = "Allow RDS PostgreSQL from EKS VPC"
    from_port        = 5432
    to_port          = 5432
    protocol         = "tcp"
    cidr_blocks      = [data.terraform_remote_state.vpc.outputs.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.name}-rds-postgresql-sg"
  }
}


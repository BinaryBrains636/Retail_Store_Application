# RDS Subnet Group for Retail Store Database
resource "aws_db_subnet_group" "retail_store" {
  name       = "retail-store-db-subnet-group-${var.environment}"
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  tags = {
    Name        = "retail-store-db-subnet-group"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name_prefix = "retail-store-rds-sg-"
  description = "Security group for RDS database"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name        = "retail-store-rds-sg"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

# Allow PostgreSQL access from EKS cluster
resource "aws_vpc_security_group_ingress_rule" "rds_from_eks" {
  security_group_id            = aws_security_group.rds.id
  referenced_security_group_id = data.terraform_remote_state.eks.outputs.cluster_security_group_id
  from_port                    = 5432
  ip_protocol                  = "tcp"
  to_port                      = 5432
  description                  = "Allow PostgreSQL access from EKS cluster"
}

# RDS Instance for Retail Store
resource "aws_db_instance" "retail_store" {
  identifier             = "retail-store-db-${var.environment}"
  engine                 = var.db_engine
  engine_version          = var.db_engine_version
  instance_class         = var.db_instance_class
  allocated_storage      = var.allocated_storage
  max_allocated_storage  = var.max_allocated_storage
  storage_type           = "gp3"
  storage_encrypted      = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  db_subnet_group_name   = aws_db_subnet_group.retail_store.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az               = false
  publicly_accessible    = false
  skip_final_snapshot    = false
  final_snapshot_identifier = "retail-store-db-final-${var.environment}"

  backup_retention_period = 7
  backup_window           = "03:00-04:00"
  maintenance_window      = "Mon:04:00-Mon:05:00"

  performance_insights_enabled = true
  monitoring_interval          = 60
  monitoring_role_arn         = aws_iam_role.rds_monitoring.arn

  deletion_protection = false

  tags = {
    Name        = "retail-store-db"
    Environment = var.environment
    Project     = "Retail Store"
  }

  depends_on = [
    aws_iam_role_policy_attachment.rds_monitoring
  ]
}

# IAM Role for RDS Enhanced Monitoring
resource "aws_iam_role" "rds_monitoring" {
  name = "rds-monitoring-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.rds.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "rds-monitoring-role"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

# Attach RDS monitoring policy
resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  role       = aws_iam_role.rds_monitoring.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}

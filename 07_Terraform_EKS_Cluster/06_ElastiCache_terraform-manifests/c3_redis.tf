# ElastiCache Subnet Group for Retail Store Redis
resource "aws_elasticache_subnet_group" "retail_store" {
  name       = "retail-store-redis-subnet-group-${var.environment}"
  subnet_ids = data.terraform_remote_state.vpc.outputs.private_subnet_ids

  tags = {
    Name        = "retail-store-redis-subnet-group"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

# Security Group for ElastiCache Redis
resource "aws_security_group" "redis" {
  name_prefix = "retail-store-redis-sg-"
  description = "Security group for ElastiCache Redis"
  vpc_id      = data.terraform_remote_state.vpc.outputs.vpc_id

  tags = {
    Name        = "retail-store-redis-sg"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

# Allow Redis access from EKS cluster
resource "aws_vpc_security_group_ingress_rule" "redis_from_eks" {
  security_group_id            = aws_security_group.redis.id
  referenced_security_group_id = data.terraform_remote_state.eks.outputs.cluster_security_group_id
  from_port                    = var.port
  ip_protocol                  = "tcp"
  to_port                      = var.port
  description                  = "Allow Redis access from EKS cluster"
}

# ElastiCache Redis Parameter Group
resource "aws_elasticache_parameter_group" "retail_store" {
  family = var.parameter_group_family
  name   = "retail-store-redis-params-${var.environment}"

  parameter {
    name  = "maxmemory-policy"
    value = "allkeys-lru"
  }

  parameter {
    name  = "timeout"
    value = "300"
  }
}

# Generate Redis auth token
resource "random_password" "redis_auth_token" {
  length  = 32
  special = false
}

# ElastiCache Redis Cluster
resource "aws_elasticache_replication_group" "retail_store" {
  replication_group_id = "retail-store-redis-${var.environment}"
  description          = "Retail Store Redis Cache"
  node_type            = var.node_type
  num_cache_clusters   = var.num_cache_nodes
  engine               = "redis"
  engine_version       = var.engine_version
  parameter_group_name = aws_elasticache_parameter_group.retail_store.name
  port                 = var.port

  subnet_group_name  = aws_elasticache_subnet_group.retail_store.name
  security_group_ids = [aws_security_group.redis.id]

  automatic_failover_enabled = false
  multi_az_enabled           = false

  at_rest_encryption_enabled = true
  transit_encryption_enabled = true
  auth_token                 = random_password.redis_auth_token.result

  snapshot_retention_limit = 5
  snapshot_window          = "02:00-03:00"
  maintenance_window       = "Mon:03:00-Mon:04:00"

  apply_immediately = false

  tags = {
    Name        = "retail-store-redis"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

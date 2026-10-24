# Outputs for ElastiCache Redis

output "redis_endpoint" {
  description = "Redis primary endpoint"
  value       = aws_elasticache_replication_group.retail_store.primary_endpoint_address
}

output "redis_port" {
  description = "Redis port"
  value       = aws_elasticache_replication_group.retail_store.port
}

output "redis_engine_version" {
  description = "Redis engine version"
  value       = aws_elasticache_replication_group.retail_store.engine_version
}

output "redis_node_type" {
  description = "Redis node type"
  value       = aws_elasticache_replication_group.retail_store.node_type
}

output "redis_security_group_id" {
  description = "Security group ID for Redis"
  value       = aws_security_group.redis.id
}

output "redis_auth_token" {
  description = "Redis auth token"
  value       = random_password.redis_auth_token.result
  sensitive   = true
}

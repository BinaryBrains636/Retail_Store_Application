# Outputs for RDS Database

output "rds_instance_endpoint" {
  description = "RDS instance endpoint"
  value       = aws_db_instance.retail_store.endpoint
}

output "rds_instance_id" {
  description = "RDS instance ID"
  value       = aws_db_instance.retail_store.id
}

output "rds_instance_arn" {
  description = "RDS instance ARN"
  value       = aws_db_instance.retail_store.arn
}

output "rdb_instance_address" {
  description = "RDS instance address"
  value       = aws_db_instance.retail_store.address
}

output "rds_security_group_id" {
  description = "Security group ID for RDS"
  value       = aws_security_group.rds.id
}

output "rds_db_name" {
  description = "Database name"
  value       = aws_db_instance.retail_store.db_name
  sensitive   = true
}

output "rds_username" {
  description = "Database master username"
  value       = aws_db_instance.retail_store.username
  sensitive   = true
}

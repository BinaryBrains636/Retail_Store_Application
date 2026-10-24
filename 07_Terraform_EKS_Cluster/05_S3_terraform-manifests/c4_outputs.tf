# Outputs for S3 Storage

output "assets_bucket_name" {
  description = "Name of the assets S3 bucket"
  value       = aws_s3_bucket.retail_store_assets.id
}

output "assets_bucket_arn" {
  description = "ARN of the assets S3 bucket"
  value       = aws_s3_bucket.retail_store_assets.arn
}

output "logs_bucket_name" {
  description = "Name of the logs S3 bucket"
  value       = aws_s3_bucket.retail_store_logs.id
}

output "logs_bucket_arn" {
  description = "ARN of the logs S3 bucket"
  value       = aws_s3_bucket.retail_store_logs.arn
}

output "s3_vpc_endpoint_id" {
  description = "ID of the S3 VPC endpoint"
  value       = aws_vpc_endpoint.s3.id
}

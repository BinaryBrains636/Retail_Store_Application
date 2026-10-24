# Variables for S3 Storage

variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, production)"
  type        = string
  default     = "production"
}

variable "eks_cluster_security_group_id" {
  description = "Security group ID of EKS cluster to allow access"
  type        = string
}



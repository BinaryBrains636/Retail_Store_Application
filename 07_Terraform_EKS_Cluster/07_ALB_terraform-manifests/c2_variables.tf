# Variables for Application Load Balancer

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

variable "certificate_arn" {
  description = "ACM certificate ARN for HTTPS (optional)"
  type        = string
  default     = null
}

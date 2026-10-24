variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment_name" {
  description = "Environment name"
  type        = string
  default     = "retail-store"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

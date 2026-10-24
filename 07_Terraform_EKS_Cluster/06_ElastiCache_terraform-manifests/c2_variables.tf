# Variables for ElastiCache Redis

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

variable "node_type" {
  description = "Redis node type"
  type        = string
  default     = "cache.t3.micro"
}

variable "num_cache_nodes" {
  description = "Number of cache nodes"
  type        = number
  default     = 1
}

variable "engine_version" {
  description = "Redis engine version"
  type        = string
  default     = "7.1"
}

variable "parameter_group_family" {
  description = "Redis parameter group family"
  type        = string
  default     = "redis7"
}

variable "port" {
  description = "Redis port"
  type        = number
  default     = 6379
}



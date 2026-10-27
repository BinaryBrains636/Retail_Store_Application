terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  services = ["ui", "cart", "catalog", "checkout", "orders", "users"]
}

resource "aws_ecr_repository" "retail_store" {
  for_each = toset(local.services)

  name                 = "retail-store/${each.value}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Environment = var.environment
    Project     = "retail-store"
  }
}



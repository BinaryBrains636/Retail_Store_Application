# ECR Repositories for Retail Store Application

# ECR Repository for UI Service
resource "aws_ecr_repository" "ui" {
  name                 = "retail-store/ui"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "retail-store-ui"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

# ECR Repository for Cart Service
resource "aws_ecr_repository" "cart" {
  name                 = "retail-store/cart"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "retail-store-cart"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

# ECR Repository for Catalog Service
resource "aws_ecr_repository" "catalog" {
  name                 = "retail-store/catalog"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "retail-store-catalog"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

# ECR Repository for Orders Service
resource "aws_ecr_repository" "orders" {
  name                 = "retail-store/orders"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "retail-store-orders"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

# ECR Repository for Checkout Service
resource "aws_ecr_repository" "checkout" {
  name                 = "retail-store/checkout"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "retail-store-checkout"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

# ECR Repository for Users/Auth Service
resource "aws_ecr_repository" "users" {
  name                 = "retail-store/users"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  encryption_configuration {
    encryption_type = "AES256"
  }

  tags = {
    Name        = "retail-store-users"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

# Lifecycle Policy for UI Repository
resource "aws_ecr_lifecycle_policy" "ui" {
  repository = aws_ecr_repository.ui.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Lifecycle Policy for Cart Repository
resource "aws_ecr_lifecycle_policy" "cart" {
  repository = aws_ecr_repository.cart.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Lifecycle Policy for Catalog Repository
resource "aws_ecr_lifecycle_policy" "catalog" {
  repository = aws_ecr_repository.catalog.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Lifecycle Policy for Orders Repository
resource "aws_ecr_lifecycle_policy" "orders" {
  repository = aws_ecr_repository.orders.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Lifecycle Policy for Checkout Repository
resource "aws_ecr_lifecycle_policy" "checkout" {
  repository = aws_ecr_repository.checkout.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Lifecycle Policy for Users Repository
resource "aws_ecr_lifecycle_policy" "users" {
  repository = aws_ecr_repository.users.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = 10
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

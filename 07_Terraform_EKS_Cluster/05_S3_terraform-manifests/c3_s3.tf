# S3 Bucket for Retail Store Static Assets
resource "aws_s3_bucket" "retail_store_assets" {
  bucket = "retail-store-assets-${var.environment}-${random_id.bucket_suffix.hex}"

  tags = {
    Name        = "retail-store-assets"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

# Random suffix for unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# S3 Bucket Versioning
resource "aws_s3_bucket_versioning" "retail_store_assets" {
  bucket = aws_s3_bucket.retail_store_assets.id
  versioning_configuration {
    status = "Enabled"
  }
}

# S3 Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "retail_store_assets" {
  bucket = aws_s3_bucket.retail_store_assets.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket Public Access Block (Private by default)
resource "aws_s3_bucket_public_access_block" "retail_store_assets" {
  bucket = aws_s3_bucket.retail_store_assets.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle Policy
resource "aws_s3_bucket_lifecycle_configuration" "retail_store_assets" {
  bucket = aws_s3_bucket.retail_store_assets.id

  rule {
    id     = "retail-store-lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 365
    }
  }
}

# S3 Bucket for Application Logs
resource "aws_s3_bucket" "retail_store_logs" {
  bucket = "retail-store-logs-${var.environment}-${random_id.log_bucket_suffix.hex}"

  tags = {
    Name        = "retail-store-logs"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

resource "random_id" "log_bucket_suffix" {
  byte_length = 4
}

resource "aws_s3_bucket_versioning" "retail_store_logs" {
  bucket = aws_s3_bucket.retail_store_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "retail_store_logs" {
  bucket = aws_s3_bucket.retail_store_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "retail_store_logs" {
  bucket = aws_s3_bucket.retail_store_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket Lifecycle for Logs
resource "aws_s3_bucket_lifecycle_configuration" "retail_store_logs" {
  bucket = aws_s3_bucket.retail_store_logs.id

  rule {
    id     = "retail-store-logs-lifecycle"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    expiration {
      days = 90
    }
  }
}

# S3 VPC Gateway Endpoint for Private Access
resource "aws_vpc_endpoint" "s3" {
  vpc_id       = data.terraform_remote_state.vpc.outputs.vpc_id
  service_name = "com.amazonaws.${var.aws_region}.s3"

  tags = {
    Name        = "s3-vpc-endpoint"
    Environment = var.environment
    Project     = "Retail Store"
  }
}

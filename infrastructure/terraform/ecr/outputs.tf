output "ecr_repository_urls" {
  description = "ECR repository URLs"
  value = {
    for k, v in aws_ecr_repository.retail_store : k => v.repository_url
  }
}

output "ecr_repository_names" {
  description = "ECR repository names"
  value = {
    for k, v in aws_ecr_repository.retail_store : k => v.name
  }
}

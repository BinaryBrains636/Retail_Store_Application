# Outputs for ECR Repositories

output "ecr_repository_urls" {
  description = "URLs of all ECR repositories"
  value = {
    ui       = "${aws_ecr_repository.ui.registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.ui.name}"
    cart     = "${aws_ecr_repository.cart.registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.cart.name}"
    catalog  = "${aws_ecr_repository.catalog.registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.catalog.name}"
    orders   = "${aws_ecr_repository.orders.registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.orders.name}"
    checkout = "${aws_ecr_repository.checkout.registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.checkout.name}"
    users    = "${aws_ecr_repository.users.registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.users.name}"
  }
}

output "ecr_repository_arns" {
  description = "ARNs of all ECR repositories"
  value = {
    ui       = aws_ecr_repository.ui.arn
    cart     = aws_ecr_repository.cart.arn
    catalog  = aws_ecr_repository.catalog.arn
    orders   = aws_ecr_repository.orders.arn
    checkout = aws_ecr_repository.checkout.arn
    users    = aws_ecr_repository.users.arn
  }
}

output "ecr_repository_names" {
  description = "Names of all ECR repositories"
  value = {
    ui       = aws_ecr_repository.ui.name
    cart     = aws_ecr_repository.cart.name
    catalog  = aws_ecr_repository.catalog.name
    orders   = aws_ecr_repository.orders.name
    checkout = aws_ecr_repository.checkout.name
    users    = aws_ecr_repository.users.name
  }
}

output "docker_login_command" {
  description = "Command to login to ECR"
  value       = "aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin $(aws sts get-caller-identity --query Account --output text).dkr.ecr.${var.aws_region}.amazonaws.com"
}

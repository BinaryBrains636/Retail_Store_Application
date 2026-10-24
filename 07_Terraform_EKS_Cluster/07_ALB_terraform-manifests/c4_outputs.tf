# Outputs for Application Load Balancer

output "alb_dns_name" {
  description = "DNS name of the load balancer"
  value       = aws_lb.retail_store.dns_name
}

output "alb_arn" {
  description = "ARN of the load balancer"
  value       = aws_lb.retail_store.arn
}

output "alb_zone_id" {
  description = "Zone ID of the load balancer"
  value       = aws_lb.retail_store.zone_id
}

output "alb_security_group_id" {
  description = "Security group ID of the ALB"
  value       = aws_security_group.alb.id
}

output "ui_target_group_arn" {
  description = "ARN of the UI target group"
  value       = aws_lb_target_group.ui.arn
}

output "api_target_group_arn" {
  description = "ARN of the API target group"
  value       = aws_lb_target_group.api.arn
}

output "alb_url" {
  description = "URL of the load balancer"
  value       = "http://${aws_lb.retail_store.dns_name}"
}

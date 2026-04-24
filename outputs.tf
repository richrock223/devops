output "nlb_dns_names" {
  description = "DNS names of the Network Load Balancers"
  value       = { for i, nlb in aws_lb.nlb : nlb.name => nlb.dns_name }
}

output "nlb_arns" {
  description = "ARNs of the Network Load Balancers"
  value       = { for i, nlb in aws_lb.nlb : nlb.name => nlb.arn }
}

output "target_group_arns" {
  description = "ARNs of the Target Groups"
  value       = { for i, tg in aws_lb_target_group.nlb_tg : tg.name => tg.arn }
}

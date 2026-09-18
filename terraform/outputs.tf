output "vpc_id" {
  value = aws_vpc.main.id
}

output "availability_zones" {
  value = local.azs
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "private_subnet_ids" {
  value = aws_subnet.private[*].id
}

output "public_route_table_id" {
  value = aws_route_table.public.id
}

output "private_route_table_ids" {
  value = aws_route_table.private[*].id
}

output "s3_gateway_endpoint_id" {
  value = aws_vpc_endpoint.s3.id
}

output "ssm_interface_endpoint_ids" {
  value = { for k, v in aws_vpc_endpoint.ssm : k => v.id }
}

output "flow_log_group" {
  value = aws_cloudwatch_log_group.vpc_flow_logs.name
}

output "nat_gateway_ids" {
  value = aws_nat_gateway.this[*].id
}

output "test_instance_id" {
  value = try(aws_instance.test[0].id, null)
}

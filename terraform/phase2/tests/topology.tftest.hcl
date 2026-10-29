mock_provider "aws" {
  mock_data "aws_availability_zones" {
    defaults = { names = ["us-west-2a", "us-west-2b"] }
  }
  mock_data "aws_ssm_parameter" {
    defaults = { value = "ami-0123456789abcdef0" }
  }
}

run "disabled_by_default" {
  command = plan
  assert {
    condition     = length(aws_vpc.lab) == 0 && length(aws_instance.host) == 0 && length(aws_route53_zone.lab) == 0 && length(aws_vpc_endpoint.ssm) == 0 && length(aws_route53_record.negative_cache) == 0
    error_message = "Default configuration must not provision lab resources."
  }
}

run "network_only" {
  command = plan
  variables { deploy_lab = true }
  assert {
    condition     = length(aws_vpc.lab) == 2 && length(aws_route.peer) == 2 && length(aws_instance.host) == 0 && length(aws_vpc_endpoint.ssm) == 0 && length(aws_route53_record.negative_cache) == 1
    error_message = "Network-only gate must keep EC2 and endpoints disabled."
  }
}

run "private_validation_topology" {
  command = apply
  variables {
    deploy_lab        = true
    enable_test_hosts = true
  }
  assert {
    condition     = length(aws_instance.host) == 2 && length(aws_vpc_endpoint.ssm) == 4
    error_message = "Expected two private hosts and local SSM endpoints in each VPC."
  }
  assert {
    condition     = alltrue([for host in aws_instance.host : host.associate_public_ip_address == false && host.metadata_options[0].http_tokens == "required"])
    error_message = "Test hosts require private addressing and IMDSv2."
  }
  assert {
    condition     = aws_route.peer["a"].destination_cidr_block == "10.53.0.0/16" && aws_route.peer["b"].destination_cidr_block == "10.52.0.0/16"
    error_message = "Both directions require the peer CIDR, not a default route."
  }
  assert {
    condition     = aws_route53_record.negative_cache[0].ttl == 60 && endswith(one(aws_route53_record.negative_cache[0].records), " 60") && length(aws_route53_zone.lab[0].vpc) == 2 && aws_vpc_peering_connection_options.dns[0].requester[0].allow_remote_vpc_dns_resolution && aws_vpc_peering_connection_options.dns[0].accepter[0].allow_remote_vpc_dns_resolution
    error_message = "DNS requires two PHZ associations and bilateral peering options."
  }
}

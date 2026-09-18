# Phase 1 Healthy-Baseline Validation Checklist

Record command output/screenshots only where useful; do not capture secrets.

## Terraform

- [ ] `terraform fmt -recursive -check` passes
- [ ] `terraform validate` passes
- [ ] plan contains only expected Phase 1 resources
- [ ] apply completes without unexpected replacement/drift

## VPC architecture

- [ ] VPC CIDR is correct
- [ ] two AZs are in use
- [ ] two public subnets exist
- [ ] two private subnets exist
- [ ] public subnets are associated with the public route table
- [ ] public route table has `0.0.0.0/0 -> IGW`
- [ ] private route tables do not have an IGW route

## S3 Gateway Endpoint

- [ ] S3 endpoint type is `Gateway`
- [ ] endpoint is associated with both private route tables
- [ ] S3 prefix-list route appears in both private route tables

## Systems Manager Interface Endpoints

- [ ] `ssm` interface endpoint exists in both private subnets
- [ ] `ssmmessages` interface endpoint exists in both private subnets
- [ ] private DNS is enabled
- [ ] endpoint security group allows TCP/443 from the VPC CIDR

## Flow Logs

- [ ] VPC Flow Log exists
- [ ] destination is the expected CloudWatch Logs group
- [ ] IAM role/trust relationship is present
- [ ] records begin appearing after traffic exists

## Optional NAT validation

Only after `enable_nat_gateways = true`:

- [ ] one NAT Gateway exists in each public subnet/AZ
- [ ] each private route table uses the NAT Gateway in the same AZ
- [ ] no private route table points directly to the IGW

## Optional SSM test instance

Only after `enable_test_instance = true`:

- [ ] instance has no public IPv4 address
- [ ] instance has no inbound security-group rules
- [ ] SSM managed-instance registration succeeds
- [ ] Session Manager works without SSH/key pair
- [ ] S3 access uses the Gateway Endpoint path

## Evidence boundary

- [ ] Notes describe this as hands-on / production-like project evidence
- [ ] Notes do not describe it as professional production AWS networking tenure

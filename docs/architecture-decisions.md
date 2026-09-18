# Architecture Decisions — Phase 1

## Two Availability Zones

The baseline uses two AZs to practice multi-AZ subnet and routing design rather than a single-subnet certification demo.

## Public and private subnets

Public subnets are associated with a route table that has a default IPv4 route to an Internet Gateway. Private subnets do not route directly to the Internet Gateway.

## NAT Gateways disabled by default

NAT Gateways are optional and created only during bounded IPv4-egress validation. When enabled, the design creates one per AZ so each private subnet can use a same-AZ NAT path.

This is a learning/validation design, not a claim that two NAT Gateways are always the right cost choice for every workload.

## S3 Gateway Endpoint

Private route tables are associated with an S3 Gateway VPC Endpoint. This deliberately exercises the route-table-based Gateway Endpoint model.

## Systems Manager Interface Endpoints

The baseline creates `ssm` and `ssmmessages` Interface Endpoints with private DNS enabled. The endpoint security group allows HTTPS from the VPC CIDR.

This deliberately exercises the ENI/security-group model of Interface Endpoints and contrasts it with the S3 Gateway Endpoint.

## No inbound SSH

The optional private EC2 validation host has no inbound security-group rules and is intended for Systems Manager-based access rather than SSH.

## VPC Flow Logs

VPC Flow Logs are sent to CloudWatch Logs with short retention to support troubleshooting evidence without retaining lab logs indefinitely.

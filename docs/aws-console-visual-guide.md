# AWS Console Visual Verification Guide

This guide is the optional visual-learning companion to the Terraform and CLI workflow in this repository.

## Purpose

The goal is to connect three views of the same infrastructure:

**Terraform configuration → AWS API/CLI evidence → AWS Console representation**

Terraform remains the source of truth. Console walkthroughs are normally read-only and are used to reinforce architecture, resource relationships, and troubleshooting intuition.

## Visual Learning Modes

- **GUI ASK** — default. Offer the visual walkthrough at meaningful checkpoints.
- **GUI ALWAYS** — include the Console walkthrough at every meaningful checkpoint.
- **GUI OFF** — skip Console walkthroughs.
- **SHOW GUI** — show the Console walkthrough for the current checkpoint only.
- **SKIP GUI** — skip the current Console walkthrough only.

These are workflow choices, not Terraform variables.

## Console safety rule

Do not manually change Terraform-managed resources in the Console unless the lab step explicitly says the change is part of a failure/drift exercise.

Normal configuration changes should be made in Terraform, reviewed with `terraform plan`, and applied through Terraform.

## Checkpoint 1 — VPC

**Terraform:** `aws_vpc.main`

**Navigate:** AWS Console → VPC → Your VPCs

Look for the project VPC.

Inspect:

- IPv4 CIDR
- DNS resolution
- DNS hostnames
- tags

Understand:

- the VPC is the network boundary for the Phase 1 environment;
- its CIDR contains all four Phase 1 subnets.

Do not manually edit the CIDR or DNS settings.

## Checkpoint 2 — Subnets

**Terraform:** `aws_subnet.public[*]`, `aws_subnet.private[*]`

**Navigate:** AWS Console → VPC → Subnets

Inspect:

- subnet name
- CIDR
- Availability Zone
- VPC association
- auto-assign public IPv4 setting

Understand:

- Phase 1 uses two AZs;
- each AZ has one public and one private subnet;
- auto-assign public IPv4 may be disabled even on a public subnet;
- public/private behavior is determined primarily by routing, not the subnet name.

## Checkpoint 3 — Route Tables

**Terraform:** `aws_route_table.public`, `aws_route_table.private[*]`, route-table associations

**Navigate:** AWS Console → VPC → Route tables

Inspect the public route table:

- associated public subnets
- local VPC route
- `0.0.0.0/0` route to the Internet Gateway

Inspect each private route table:

- associated private subnet
- local VPC route
- S3 prefix-list route through the S3 Gateway Endpoint
- absence of a direct Internet Gateway default route
- NAT default route only when the bounded NAT test is enabled

Understand:

- a subnet becomes publicly routed when its route table provides a default path to an Internet Gateway;
- the private subnets initially have no general IPv4 internet egress.

## Checkpoint 4 — Internet Gateway

**Terraform:** `aws_internet_gateway.main`

**Navigate:** AWS Console → VPC → Internet gateways

Inspect:

- attachment to the project VPC
- project tags

Understand:

- the IGW alone does not make every subnet public;
- route-table association determines which subnets can use it.

## Checkpoint 5 — Security Groups

**Terraform:** endpoint and validation-instance security groups

**Navigate:** AWS Console → VPC → Security groups

For the interface-endpoint SG, inspect:

- inbound TCP/443 from the lab VPC CIDR
- outbound behavior

For the optional test-instance SG, inspect:

- no inbound SSH requirement
- expected outbound access

Understand:

- Security Groups are stateful;
- the SSM interface endpoints need HTTPS connectivity from the private resources that use them.

## Checkpoint 6 — Network ACL

**Terraform:** `aws_network_acl.private`

**Navigate:** AWS Console → VPC → Network ACLs

Inspect:

- private-subnet associations
- inbound rules
- outbound rules

Understand:

- NACLs are stateless;
- return traffic must be allowed independently;
- later failure drills intentionally use this distinction.

Do not alter rules manually unless the drill explicitly calls for a Console-based observation/change.

## Checkpoint 7 — S3 Gateway Endpoint

**Terraform:** `aws_vpc_endpoint.s3`

**Navigate:** AWS Console → VPC → Endpoints

Locate the S3 endpoint and inspect:

- service name
- endpoint type: Gateway
- state
- VPC
- associated route tables

Then return to the private route tables and observe the S3 prefix-list route.

Understand:

- S3 Gateway Endpoints integrate through route tables;
- they do not create endpoint ENIs in the subnets.

## Checkpoint 8 — Systems Manager Interface Endpoints

**Terraform:** `aws_vpc_endpoint.ssm["ssm"]`, `aws_vpc_endpoint.ssm["ssmmessages"]`

**Navigate:** AWS Console → VPC → Endpoints

Inspect each endpoint:

- endpoint type: Interface
- state
- private DNS
- subnets
- security group
- network interfaces

Understand:

- Interface Endpoints create private ENIs;
- private DNS lets normal regional service names resolve to the private endpoint path inside the VPC;
- this is visually different from the S3 Gateway Endpoint.

## Checkpoint 9 — Endpoint ENIs

**Navigate:** AWS Console → EC2 → Network Interfaces

Filter by the endpoint descriptions or project VPC.

Inspect:

- private IP addresses
- subnet placement
- Availability Zone
- attached security group

Understand:

- Interface Endpoint ENIs are the private network entry points to the AWS service.

## Checkpoint 10 — VPC Flow Logs

**Terraform:** `aws_flow_log.vpc`

**Navigate:** AWS Console → VPC → Your VPCs → select project VPC → Flow logs

Inspect:

- status
- traffic type
- destination

Then navigate:

AWS Console → CloudWatch → Log groups → `/aws-networking-rebuild/vpc-flow-logs`

Inspect:

- retention
- log streams after traffic has been generated
- representative ACCEPT/REJECT records during later troubleshooting

Understand:

- Flow Logs provide network metadata for evidence-driven troubleshooting;
- raw logs should not be copied into the public repository without review/sanitization.

## Checkpoint 11 — Private EC2 Validation Instance

Only after `enable_test_instance = true`.

**Navigate:** AWS Console → EC2 → Instances

Inspect:

- private subnet
- no public IPv4 address
- IAM instance profile
- security group
- instance state

Then navigate:

AWS Console → Systems Manager → Fleet Manager / Managed nodes or Session Manager

Understand:

- the management path should work without inbound SSH;
- before NAT is enabled, Systems Manager connectivity should rely on the private interface endpoints.

## Checkpoint 12 — NAT Gateway

Only during the bounded NAT test window.

**Navigate:** AWS Console → VPC → NAT gateways

Inspect:

- public subnet placement
- Availability Zone
- Elastic IP
- state

Then inspect the private route tables for the corresponding NAT default routes.

Understand:

- NAT provides outbound IPv4 internet access for private resources;
- it is billable and should remain enabled only for the bounded test window;
- same-AZ routing is used in this project to avoid unnecessary cross-AZ data paths.

## Checkpoint 13 — Failure / Troubleshooting View

During a deliberate failure drill, use the Console only as one source of evidence.

Recommended sequence:

1. observe the symptom;
2. form a hypothesis;
3. inspect Terraform configuration;
4. inspect CLI/API evidence;
5. use the Console to visualize routes, associations, SG/NACL rules, endpoints, ENIs, and Flow Logs;
6. identify the root cause;
7. fix through Terraform unless the drill explicitly authorizes another method;
8. revalidate;
9. record the result in the troubleshooting log.

## Recording visual verification

Visual verification is optional evidence. It does not replace Terraform/CLI validation.

When performed, `docs/validation-evidence.md` may record:

- AWS Console walkthrough performed: YES
- VPC/subnet layout visually confirmed: PASS
- route-table behavior visually confirmed: PASS
- endpoint types visually confirmed: PASS
- Flow Log / CloudWatch relationship visually confirmed: PASS

Do not commit screenshots that expose AWS account IDs, ARNs, user identities, unrelated resources, or other sensitive/private information without sanitization.

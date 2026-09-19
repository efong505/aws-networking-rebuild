# Phase 1 Validation Evidence

**Status:** Deployed; healthy baseline validation in progress

Use this file for concise, sanitized evidence after deployment. Do not paste unreviewed AWS CLI output.

## Terraform baseline

- Date performed: 2026-09-18
- `terraform fmt -recursive -check`: PASS
- `terraform validate`: PASS
- Plan reviewed before apply: PASS — 27 to add, 0 to change, 0 to destroy
- Apply result: PASS — 27 added, 0 changed, 0 destroyed

## VPC / subnet / routing validation

- Two AZs confirmed: PASS
- Public subnet associations confirmed: PASS
- Private subnet associations confirmed: PASS
- Public `0.0.0.0/0 -> IGW` route confirmed: PASS
- Private subnets have no direct IGW route: PASS

## S3 Gateway Endpoint

- Endpoint type confirmed: Gateway
- Both private route tables associated: PASS
- S3 prefix-list routes observed: PASS

## Systems Manager Interface Endpoints

- `ssm` endpoint validated: PASS
- `ssmmessages` endpoint validated: PASS
- Private DNS validated: PASS
- Endpoint SG TCP/443 behavior validated: PASS

## Flow Logs

- Flow Log active: PASS
- CloudWatch destination confirmed: PASS
- Traffic records observed: Pending traffic generation

## Optional bounded test window

- Private EC2 instance had no public IPv4:
- Session Manager connectivity:
- NAT egress validation:
- S3 private-path validation:

## Teardown verification

- Terraform destroy completed:
- NAT Gateways absent:
- EIPs released:
- Interface endpoints removed:
- Test EC2 absent:
- Any intentionally retained resources:

## Evidence classification

These results are hands-on production-like project evidence and are not professional production AWS-networking tenure.

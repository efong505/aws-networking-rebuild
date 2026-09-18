# Phase 1 Validation Evidence

**Status:** Pre-apply validation complete; deployment not yet performed

Use this file for concise, sanitized evidence after deployment. Do not paste unreviewed AWS CLI output.

## Terraform baseline

- Date performed: 2026-09-18
- `terraform fmt -recursive -check`: PASS
- `terraform validate`: PASS
- Plan reviewed before apply: Success! The configuration is valid.
- Apply result: Not yet performed.

## VPC / subnet / routing validation

- Two AZs confirmed:
- Public subnet associations confirmed:
- Private subnet associations confirmed:
- Public `0.0.0.0/0 -> IGW` route confirmed:
- Private subnets have no direct IGW route:

## S3 Gateway Endpoint

- Endpoint type confirmed:
- Both private route tables associated:
- S3 prefix-list routes observed:

## Systems Manager Interface Endpoints

- `ssm` endpoint validated:
- `ssmmessages` endpoint validated:
- Private DNS validated:
- Endpoint SG TCP/443 behavior validated:

## Flow Logs

- Flow Log active:
- CloudWatch destination confirmed:
- Traffic records observed:

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

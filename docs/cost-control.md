# Cost Control

This lab is intentionally designed so the highest-cost optional components are disabled by default.

Potentially billable resources include:

- NAT Gateways (hourly plus data processing)
- Interface VPC Endpoints (hourly plus data processing)
- EC2 test instance
- public IPv4/EIP usage
- CloudWatch Logs ingestion/storage

The S3 Gateway Endpoint has no additional endpoint charge.

## Rules

1. Keep `enable_nat_gateways = false` until the NAT/egress validation window.
2. Keep `enable_test_instance = false` until SSM validation.
3. When NAT testing begins, create, test, document, and destroy in the same bounded session when practical.
4. Keep Flow Log retention short for the lab.
5. Always run a final `terraform plan -destroy` / `terraform destroy` and verify no lab resources remain.
6. Do not leave resources running solely to make the portfolio project appear more "production".

# Phase 1 Validation Evidence

**Status:** Phase 1 validated; routing and security-group break/fix exercises completed; infrastructure destroyed. Public-readiness approval pending.

This is a sanitized evidence summary of a hands-on independent production-like AWS networking project. Observations from the prior repository record are retained; later findings are drawn from the owner-provided October 27, 2026 handoff. No missing raw command outputs, timestamps, or screenshots have been reconstructed.

## Terraform baseline — 2026-09-18

- `terraform fmt -recursive -check`: PASS
- `terraform validate`: PASS
- Plan reviewed before apply: PASS — 27 to add, 0 to change, 0 to destroy
- Apply result: PASS — 27 added, 0 changed, 0 destroyed

## VPC / subnet / routing validation

- Region: `us-west-2`; VPC: `10.42.0.0/16`.
- Two AZs confirmed: PASS (`us-west-2a`, `us-west-2b`).
- Two public and two private subnet associations confirmed: PASS.
- Public `0.0.0.0/0 -> IGW` route confirmed: PASS.
- Private subnets had no direct IGW route: PASS.
- Two NAT Gateways (one per AZ) were enabled for bounded testing, with same-AZ private default routes.

## Private EC2 and Systems Manager

- Private Amazon Linux EC2 without public IPv4: VALIDATED.
- SSM management through private interface endpoints: VALIDATED without inbound SSH.
- IAM instance profile supporting SSM and required IMDSv2: configured and validated as part of the test.
- `ssm` and `ssmmessages` endpoints, private DNS, and endpoint SG TCP/443: prior baseline PASS.

## S3 Gateway Endpoint

- Endpoint type: Gateway; both private route tables associated: PASS.
- S3 prefix-list routes observed: PASS.
- Private instance reached S3 without requiring NAT internet egress: VALIDATED.
- An HTTP 405 response from an S3 request demonstrated network reachability, **not successful object retrieval**.

## NAT Gateway egress

- Before NAT/default-route enablement, external HTTPS was unreachable.
- After enabling per-AZ NAT Gateways and private default routes, external HTTPS to `https://example.com` returned HTTP 200.
- Observed public egress IP matched the Elastic IP of the NAT Gateway in the instance's AZ.

## VPC Flow Logs

- Flow Log active: PASS; CloudWatch Logs destination confirmed: PASS.
- Actual traffic records were observed, including private AWS-service traffic.
- No packet capture or advanced telemetry is claimed.

## Controlled fault/recovery evidence

1. **Missing private default route:** Removing `0.0.0.0/0` caused external HTTPS timeout; S3 remained reachable through its endpoint. Restoring the NAT route returned HTTP 200. Terraform reported `No changes. Your infrastructure matches the configuration.`
2. **Revoked EC2 security-group outbound permission:** User confirmed expected connectivity failure and successful restoration. Terraform subsequently reported no changes. **Full raw command outputs were not retained**; this is user-confirmed evidence, not independently preserved output.

See [troubleshooting log](troubleshooting-log.md) for symptom, hypothesis, evidence, root cause, fix, and prevention.

## Teardown verification

- `terraform destroy`: completed.
- NAT Gateway A and B: CLI reported **deleted**.
- EC2 validation instance: CLI reported **terminated**.
- Lab VPC: CLI lookup **not found**.
- Terraform state: **empty**.
- CloudWatch Log Group: initially remained after destroy; user subsequently deleted it. **No independent final CloudWatch lookup was supplied.**
- EIP release, all interface endpoints, every potential residual billable resource, and comprehensive account-wide cleanup: **not independently established by the supplied final evidence**.

## Optional visual verification

AWS Console visual-verification workflow exists in [the visual guide](aws-console-visual-guide.md), but completed screenshots/visual checklist results are not established by this record. No visual confirmation is invented.

## Evidence classification and remaining gates

Independent hands-on production-like project evidence, **not professional production AWS networking tenure**. Public repository security/history review and final public-readiness approval remain separate gates.

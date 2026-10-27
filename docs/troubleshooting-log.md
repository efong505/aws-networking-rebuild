# Troubleshooting / Failure-Recovery Log

These were controlled failures in an **independent hands-on production-like project exercise**, not employer production incidents. Exact drill dates and some raw outputs were not retained; no timestamps or command transcripts are reconstructed.

## Drill 1 — Private subnet default-route removal

- **Date:** Not preserved in handoff.
- **Healthy baseline verified before fault:** External HTTPS from private EC2 succeeded through its same-AZ NAT Gateway.
- **Controlled fault introduced:** Removed the private route table's `0.0.0.0/0` default route.
- **Symptom:** External HTTPS timed out, while S3 connectivity remained available.
- **Initial hypothesis:** Loss of a usable internet-bound route from the private subnet, not a total failure of private AWS-service connectivity.
- **Evidence checked:** Private route table retained local and S3 prefix-list routes; external HTTPS timed out; S3 remained reachable.
- **Root cause:** Missing default route to the NAT Gateway.
- **Fix:** Restored `0.0.0.0/0` pointing to the appropriate NAT Gateway.
- **Validation after fix:** External HTTPS returned HTTP 200; Terraform reported `No changes. Your infrastructure matches the configuration.`
- **Prevention / design lesson:** Validate effective subnet routes and distinguish S3 Gateway Endpoint routing from NAT internet egress; reconcile controlled drift with Terraform.
- **Evidence classification:** Independent hands-on production-like project exercise.

## Drill 2 — EC2 outbound security-group permission revoked

- **Date:** Not preserved in handoff.
- **Healthy baseline verified before fault:** Outbound HTTPS connectivity was functioning.
- **Controlled fault introduced:** Revoked the private EC2 instance security group's outbound allow-all rule.
- **Symptom:** Expected outbound connectivity failure reproduced, **user-confirmed**.
- **Initial hypothesis:** Instance-level egress permissions blocked traffic even with the routing path available.
- **Evidence checked:** User confirmation of the failed connectivity test after revocation. Full original command outputs were not retained.
- **Root cause:** Missing outbound security-group allow rule.
- **Fix:** Restored the outbound rule.
- **Validation after fix:** User confirmed tests passed; Terraform again reported no changes. Raw output is not preserved in this handoff.
- **Prevention / design lesson:** Check security-group egress independently of route tables, restore intentional changes, and reconcile Terraform drift.
- **Evidence classification:** Independent hands-on production-like project exercise; results user-confirmed, not independently preserved command transcripts.

## Scope limits

Other suggested drills in [failure-drills.md](failure-drills.md) (route-table reassociation, interface endpoint security-group blocking, and NACL denial) are **not claimed as performed**. These records do not establish employer production incident ownership.

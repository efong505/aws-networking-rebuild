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

## Phase 2 — missing reciprocal route (October 27, 2026 local)

- Healthy baseline: both directions passed private-IP and custom-name pings, 3/3 packets each, and expected DNS answers.
- Fault: removed only B's route to A's 10.52.0.0/16 network.
- Symptom/evidence: 2/2 packets lost in both directions while private names still resolved.
- Root cause: missing forward/return route in B, not a DNS failure.
- Fix: reviewed Terraform plan recreated only B's route.
- Recovery: both directions passed DNS, IP/name pings with 0% loss; real plan reported no changes.
- Prevention: inspect reciprocal effective routes and retain local SSM recovery paths.

## Phase 2 — missing A record and negative-cache recovery (October 27–28 local)

- Fault: deleted only A's private A record; waited for INSYNC and TTL interval.
- Symptom: B's getent lookup failed while IP ping to A passed 3/3. The immediately preceding dig still returned an A answer; do not claim uniform DNS failure at that instant.
- Evidence checked: Route 53 records/changes, direct DNS responses, getent, local resolver/cache diagnostics and continued IP reachability.
- Fix: reviewed Terraform plan recreated only A's record. B initially still returned NXDOMAIN while the API showed A present, with an older SOA negative TTL in responses. A never-created name reflected the newer SOA setting.
- Prevention change: manage lab SOA TTL/minimum as 60/60; tests enforce it. The older negative response was consistent with caching; the exact reason for all earlier query inconsistencies is not established.
- Recovery: original name passed dig and getent at 04:44:33 UTC; final reusable probe on both original hosts passed all DNS/IP/name tests before teardown. Terraform found no drift.

## Phase 2 — association fault attempts (inconclusive)

Two detach/restore attempts did not reproduce the expected lookup failure, including an INSYNC + cache-interval attempt with one zone association independently observed. Both were restored. Do not count them as successful DNS failure reproductions or infer that peering automatically shares private zones.

Full [Phase 2 evidence](phase2-evidence.md) includes timestamps, limitations, teardown and the exceeded approved session window. These are independent lab exercises, not employer incidents.

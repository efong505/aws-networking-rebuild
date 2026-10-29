# Phase 2 evidence — October 27–28, 2026

## Current boundary

Core Phase 2 deployed, private connectivity/DNS validated, route and missing-record failure/recovery observed, and all lab resources destroyed. DNS-association failure reproduction remained inconclusive. The approved session time limit was exceeded; actual billing is unverified. Phase 1 evidence remains separate and complete with its documented qualifications.

## Gates

| Gate | Status |
|---|---|
| Terraform formatting | PASS — terraform fmt -recursive -check |
| Provider/schema validation | PASS — Terraform 1.14.6 / AWS provider 6.20.0 |
| Mocked topology tests | PASS — 3 tests; provider mocked, not live AWS validation |
| Account preflight and real plan | PASS — read-only plan: 28 add, 0 change, 0 destroy; ekewaka / us-west-2 |
| User cost approval / apply | Approved 2026-10-27; apply PASS — 28 added, 0 changed, 0 destroyed |
| Bidirectional private IP + custom DNS checks | PASS — both directions, expected private DNS answers, zero packet loss |
| Route/DNS fault and recovery | Route PASS; missing-record lookup failure and recovery observed; association attempts inconclusive |
| Teardown and residual-resource checks | PASS — 29 destroyed; 29 cleanup checks passed, including empty state and AWS absence checks |

See [executable configuration and staged runbook](../terraform/phase2/README.md). Record actual results here after each gate; never convert proposed tests into accomplishments.

## Read-only preflight observations

Existing regional VPC count: 1; VPC quota: 5, leaving room for 2 lab VPCs. All associated IPv4 CIDRs checked numerically: no overlap with either lab /16. No existing phase2.internal hosted zone. Real plan resource types/counts match the 28-resource runbook inventory. Raw plan/output remains local and ignored. This does not prove create permissions, EC2 capacity, every service quota or working runtime connectivity. Account selection must be confirmed privately before apply.

## Local verification qualification

The Windows environment's local Terraform/provider mutual TLS handshake failed with an unknown certificate authority. Local validate/test and the read-only plan succeeded with process-scoped TF_DISABLE_PLUGIN_TLS=1. This affects Terraform's local provider RPC channel; AWS HTTPS certificate verification was not disabled. Do not persist the workaround globally. AWS provider is pinned to the tested 6.20.0 with its committed lock file. Mock tests perform no AWS operations, including the mock apply/teardown test.

User approved the proposed 60-minute / $5 allowance session. The refreshed plan was checked for exactly 28 creates before apply. Session began 2026-10-27 at approximately 22:25 America/Denver (2026-10-28 04:25 UTC); teardown is required before 23:25 local.

## Live baseline and route drill — October 27 local / October 28 UTC

- Both private AL2023 hosts registered Online in Systems Manager without public IPv4 or inbound SSH. Registration took several minutes; transient boot-time metadata warnings were seen, but cloud-init completed and both management paths became healthy without opening internet egress.
- API checks: active peering; two active peer CIDR routes; two subnet route-table associations; both peering DNS options enabled; two VPC associations on the private zone; four available interface endpoints. Endpoint DNS answers were matched to the corresponding local endpoint ENI addresses.
- On A and B, `getent ahostsv4 <peer>.phase2.internal` returned the expected peer private IP; three-packet pings to the peer IP and private name each returned 3/3 with 0% loss. Both SSM Run Command invocations exited 0.
- Route drill: deleted only B's route to 10.52.0.0/16. Both private names still resolved; two-packet IP pings failed with 2 sent / 0 received / 100% loss in both directions. Explicit assertions confirmed these expected failures.
- Reviewed Terraform repair contained only recreation of B's peer route. After apply, both directions again passed DNS, IP and name pings with 0% loss. A real `terraform plan -detailed-exitcode` returned 0 (no changes).

## DNS-association drill — inconclusive, not a successful failure reproduction

B's private-zone association was detached while A's association was retained, then restored through reviewed one-resource Terraform updates. Two attempts continued resolving A's private name: first after 40 seconds; second after Route 53 reported INSYNC plus 40 seconds. A separate API lookup confirmed only one VPC association during the second attempt. The expected DNS failure was not observed, so neither attempt is claimed as a successful DNS break/fix drill.

Host diagnostics showed `hosts: files dns myhostname`, a VPC-local resolver, active systemd-resolved with zero populated cache entries, and inactive nscd/dnsmasq. These observations do not establish the reason resolution continued. Do not assert that peering automatically shares private zones or label the cause as proven cache/propagation behavior. The [AWS documented expectation](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zone-private-disassociate-vpcs.html) remains distinct from this bounded observation.

The separate missing-A-record drill and recovery are recorded below.

## Missing-record DNS drill — observed lookup failure, with query inconsistency retained

Deleted only A's private A record, waited for Route 53 INSYNC and more than the 30-second record TTL, then queried from B. `getent ahostsv4 a.phase2.internal` failed (the explicit failure assertion passed) while ping to A's private IP returned 3/3 with 0% loss. This separates the observed name-resolution failure from private routed connectivity.

The immediately preceding `dig @10.53.0.2 ...` still returned NOERROR and the prior A answer. Do not report NXDOMAIN from dig or a uniformly failed resolver response. The cause of the inconsistent consecutive query results was not established. Terraform repair was reviewed to recreate only A's DNS record; final recovery checks follow below.

## Negative-cache recovery finding and configuration fix

After recreating A's record, A's own tests passed but B's first recovered `dig` assertion failed. Follow-up direct queries from B to both its VPC resolver and 169.254.169.253 returned NXDOMAIN with the private zone SOA TTL of 900 seconds. B's private-IP ping still passed 3/3. The Route 53 API independently showed both A records present and the SOA TTL 900 / minimum 86400. Negative caching therefore provides an evidence-supported explanation for delayed recovery; the exact cause of the earlier association-test behavior remains unproven.

Added a managed SOA record with TTL and minimum both 60 seconds for this short-lived lab. The reviewed adjustment manages only the existing zone SOA, creates no additional billable service, and changes current Terraform inventory from 28 to 29 managed resource addresses. Mock tests were extended to assert bounded negative caching and all three tests passed. Existing cached negative answers may retain the prior TTL, so actual recovery of the original name must still be observed.

Reference: [AWS DNS best practices](https://aws.amazon.com/blogs/networking-and-content-delivery/dns-best-practices-for-amazon-route-53/) explains SOA negative caching. The 60-second setting is a disposable-drill choice, not a general production recommendation.

A live comparison query after the fix returned NXDOMAIN with SOA TTL/minimum 60 for a never-created name, while the original A name still returned the older SOA TTL 900/minimum 86400. The Route 53 API also showed the 60/60 configuration. This supports the distinction between current zone settings and an already-cached negative result; it does not prove the root cause of the earlier association-test observations.

## Recovery confirmed and session-window exception

The original A name recovered through both direct DNS and host lookup at 2026-10-28 04:44:33 UTC (October 27, 22:44:33 America/Denver), as recorded by the background recovery check. The completed check was collected when work resumed. On October 28 at approximately 05:53 local, the reusable `scripts/phase2-probe.ps1` then passed on both original hosts: direct DNS, getent, private-IP ping, private-name ping, and local endpoint lookup. Both invocations exited 0. Refreshed API checks again confirmed the expected topology, and real Terraform plan returned exit 0 / no changes.

**Cost-control exception:** The lab remained running after the previous turn stopped. The approved 60-minute window beginning October 27 at about 22:25 local was exceeded; cleanup began after resumption on October 28 at about 05:53 local. Do not report that this session met its time limit. Actual billed charges and compliance with the $5 allowance have not been verified; no billing total is inferred from resource uptime alone.

Future billable sessions require an independently verified expiration/cleanup mechanism before apply, running independently of chat continuation, plus a reserved cleanup buffer. A chat reminder, background probe, or Terraform state alone is not that mechanism. No such independent teardown guard was installed for this session.

A reviewed destroy plan contains only the 29 managed Phase 2 addresses. Destruction completed; independent AWS absence checks passed.

## Final teardown — October 28, approximately 05:58 America/Denver / 11:58 UTC

- Reviewed plan: 29 deletes from the isolated Phase 2 root; apply reported 0 added, 0 changed, 29 destroyed.
- 29 separate cleanup checks passed: both EC2s terminated; both root volumes absent; all four interface endpoints deleted/absent; all six captured endpoint/instance ENIs absent; private zone absent (including its records); both VPCs, subnets, route tables and all four explicit SGs absent; peering deleted; lab IAM role and instance profile absent; Terraform state empty. Managed policy attachment was destroyed with the role; the AWS-managed SSM policy itself was not deleted.
- This verifies the captured Phase 2 inventory, not an account-wide billing audit. Charges can lag and the actual bill has not been verified.
- [Command execution index](phase2-command-results.md) retains sanitized UTC execution metadata. Raw command requests, responses, plans, state and account/resource identifiers stay under ignored private evidence.

## Scope retained

No public-IPv4 hostname-to-private-IP peering test, custom endpoint service, Transit Gateway, hybrid Resolver deployment, custom NACL drill, packet capture, Phase 2 Flow Logs or Console screenshot verification is claimed. Peering DNS options were API-verified; custom private names were tested through the zone associated with both VPCs. Public-readiness/visibility remains a separate decision. Evidence is independent hands-on lab work, not professional enterprise networking tenure or an earned SAA certification.

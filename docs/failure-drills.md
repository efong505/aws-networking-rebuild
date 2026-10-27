# Phase 1 Failure Drills

This file contains both a completed drill and proposed exercises. **Performed:** private default-route removal and recovery, plus a separate EC2 outbound security-group revocation/recovery exercise. **Not performed:** wrong route-table association, SSM interface-endpoint security-group blocking, and NACL denial. Refer to [the troubleshooting log](troubleshooting-log.md) for actual results and evidence qualifications.

Do not begin a new drill until the healthy baseline is validated.

For each drill, capture:

**symptom → hypothesis → evidence checked → root cause → fix → prevention**

## Drill 1 — Private IPv4 internet egress failure (COMPLETED)

Prerequisite: NAT gateways and test instance temporarily enabled.

Performed controlled fault:
- removed the `0.0.0.0/0` route in one private route table; external HTTPS timed out while S3 Gateway Endpoint access remained available; restoring the route recovered HTTP 200 and Terraform reported no drift.

The alternative *mis-targeted route* variant was not performed.

Evidence to inspect:
- subnet/route-table association;
- effective routes;
- NAT Gateway state and AZ;
- VPC Flow Logs;
- instance has no public IPv4.

Expected learning:
- a private subnet does not become public merely because a route exists;
- internet-bound IPv4 egress from a private subnet normally needs a NAT path;
- per-AZ NAT routing avoids a single-AZ dependency and cross-AZ path.

## Drill 2 — Wrong route-table association (PROPOSED / NOT PERFORMED)

Suggested controlled fault:
- associate private subnet A with the other route table or a temporary route table lacking required routes.

Evidence to inspect:
- subnet associations;
- route table entries;
- S3 endpoint association;
- NAT route if enabled.

Expected learning:
- subnet behavior is determined by the route table actually associated with it, not the table name you intended.

## Drill 3 — Interface endpoint security group blocks SSM (PROPOSED / NOT PERFORMED)

Suggested controlled fault:
- temporarily remove TCP/443 inbound from the interface-endpoint security group.

Evidence to inspect:
- endpoint ENIs;
- endpoint SG rules;
- private DNS resolution;
- SSM managed-node status;
- Flow Logs ACCEPT/REJECT records.

Expected learning:
- interface endpoints use ENIs and security groups;
- Gateway Endpoints do not use endpoint ENIs/security groups in the same way.

## Drill 4 — NACL blocks intended traffic (PROPOSED / NOT PERFORMED)

Suggested controlled fault:
- add a narrowly scoped deny rule ahead of the allow rule, or replace the lab allow rule with a controlled restrictive rule.

Evidence to inspect:
- NACL rule ordering;
- stateless return-path requirements;
- Flow Logs;
- security group state.

Expected learning:
- NACLs are stateless and support explicit deny;
- security groups are stateful and allow-only.

## Additional performed drill — EC2 outbound security-group rule removal (COMPLETED; USER-CONFIRMED)

- The private EC2 instance security group's outbound allow-all rule was revoked during the bounded exercise.
- The owner reported that the expected connectivity tests failed and subsequently passed after the outbound rule was restored.
- The owner reported Terraform showed no changes after restoration.
- Full original command output was not retained. This is **user-confirmed**, not independently preserved command evidence.
- This drill is **distinct from** the unperformed interface-endpoint security-group drill above. See [troubleshooting log](troubleshooting-log.md).

## Restore

After every drill:
1. restore Terraform to the healthy definition;
2. `terraform plan`;
3. apply;
4. rerun the relevant validation check;
5. record the prevention control.

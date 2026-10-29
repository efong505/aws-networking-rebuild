# Phase 2 — isolated multi-VPC lab

## Status and boundaries

Core Phase 2 was deployed, connectivity/DNS validated, route and missing-record failure/recovery observed, and infrastructure destroyed. See [actual evidence and qualifications](../../docs/phase2-evidence.md), including inconclusive association tests and the exceeded session time limit. The procedures below are for reproduction; they do not authorize another deployment. This directory is a separate Terraform root/state, not an extension of the destroyed Phase 1 state. Both phases remain in this repository. No production resources are referenced.

Two nonoverlapping VPCs (10.52/16 and 10.53/16), one private subnet each in the same AZ, accepted same-account/same-region peering, reciprocal specific routes, bilateral DNS options, and a Route 53 private zone associated with both VPCs. Optional private AL2023 hosts use local SSM endpoints, encrypted disposable disks and IMDSv2. ICMP is allowed only from/to the peer subnet; management HTTPS remains local. No SSH, public IPv4, IGW, NAT, TGW, load balancer or Resolver endpoints. Default NACLs are used in this phase; no custom NACL drill is claimed.

Peering provides direct routing, not transitive routing or shared NAT egress. Peering DNS options and private-zone associations are separate mechanisms. The custom private names test PHZ association, not the public-hostname-to-private-IP peering feature. These hosts have no public IPv4/public hostname, so that latter feature is configured but not runtime-proven.

References: [AWS peering behavior](https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-basics.html), [peering DNS](https://docs.aws.amazon.com/vpc/latest/peering/vpc-peering-dns.html), [Route 53 private zones](https://docs.aws.amazon.com/Route53/latest/DeveloperGuide/hosted-zones-private.html).

## Staged gates

1. Local: fmt, init, validate and mocked Terraform tests. No AWS credentials are needed for mocked tests. Terraform >=1.7 is required for mocks (implementation supports >=1.6).
2. Read-only preflight: select profile/account privately, check region/permissions, existing CIDR overlap, quotas, and no conflicting phase2.internal namespace. Set an owner, approved spend allowance, teardown deadline and responsible operator. Before any future billable apply, install and verify an expiration/cleanup mechanism independent of chat continuation, and reserve a cleanup buffer. Do not rely on a chat turn or background DNS probe to guarantee teardown. Read-only plan is permitted; apply is not.
3. Review plan: expected full scope is 29 managed resources: 2 VPCs, 2 subnets, 2 route tables, 2 associations, 1 peering, 1 DNS-options resource, 2 reciprocal routes, 4 SGs, 4 endpoints, 1 role, 1 attachment, 1 instance profile, 2 EC2s, 1 private zone, 2 A records and 1 managed SOA record. Reject unrelated changes/deletes, public addressing, NAT/TGW or unexpected resources. Refresh/re-review the plan if inputs/code/account change.
4. User approval: proposed maximum 60-minute lab window and $5 spend allowance; this is an operating limit, not an automatic billing cap. No costs are authorized by repository changes. Confirm profile/account, final regional estimate and exact plan before applying.
5. Apply the reviewed saved plan, wait for both instances to be SSM Online, run baseline checks below. Stop if management access does not become healthy; diagnose or destroy within the window.
6. After healthy baseline, perform one controlled fault at a time, restore, retest and reconcile Terraform. Record actual observations.
7. Review destroy plan, destroy this root only, then verify empty state AND AWS resource absence. Update career evidence only after performed checks are documented.

## Commands (PowerShell, from this directory)

```powershell
terraform init
terraform fmt -recursive -check
terraform validate
terraform test
$env:AWS_PROFILE = '<approved-lab-profile>'
# Read-only plan, not authorization to apply:
terraform plan -var='deploy_lab=true' -var='enable_test_hosts=true' '-out=phase2.tfplan'
# ONLY after user approval and review of this exact plan:
terraform apply 'phase2.tfplan'
terraform output -json validation_targets
```

Do not invoke parent Phase 1 apply scripts here. Saved plans, state, raw outputs and account identifiers remain ignored/private. Do not publish the validation_targets output unreviewed.

## Healthy baseline / DNS validation

A repeatable probe is available from the repository root: scripts/phase2-probe.ps1 -Profile <approved-lab-profile>. It checks that both targets match the private lab instances before sending fixed SSM commands, then requires both direct DNS and host lookup plus both IP/name pings to pass. Raw output is written only under ignored vidence/private/. Do not run it during a Terraform operation. It provisions nothing and requires an already approved live lab.


Using `aws ssm start-session --target <instance-id>` (or SSM Run Command with AWS-RunShellScript), on A run:

```sh
getent ahostsv4 b.phase2.internal
ping -c 3 -W 2 <B-private-IP>
ping -c 3 -W 2 b.phase2.internal
```

On B run the corresponding `a.phase2.internal` and A private IP tests. Record exit status and sanitized output. Returned addresses must equal Terraform's opposite host private IP; a DNS answer alone does not prove connectivity. Test both directions. SSM endpoint DNS should resolve to the LOCAL endpoint private addresses in each VPC. Inspect API route-table associations, active peering routes/options and both PHZ VPC associations. Check both hosts lack public IPs. Allow up to 5 minutes for initial SSM registration; do not diagnose peering until local management is healthy.

Console checkpoint (optional GUI ASK): VPC → Peering connections → phase2-a-b; inspect status, requester/accepter and DNS settings. Route tables → phase2-a/b-private; inspect association and peer CIDR route. Route 53 → Hosted zones → phase2.internal; inspect VPC associations and A records. Observational only, except the deliberate drill below. A recorded walkthrough is required before claiming visual verification.

## Controlled drills and reproduction procedures

- Missing reciprocal route: after baseline success, save B's peer route destination and peering ID privately. Remove ONLY B's 10.52.0.0/16 route via EC2 delete-route. A→B and B→A ping should fail due to loss of return/forward path; DNS can still resolve locally. Check both effective route tables before blaming SG/DNS. Restore with `terraform apply` of a reviewed repair plan, then rerun both directions and require no drift. Keep B's local SSM endpoints untouched so recovery remains available.
- Private DNS isolation: after healthy baseline, detach only VPC B's PHZ association (retain A). Wait for the disassociation change to report `INSYNC`, then wait beyond the 30-second TTL/cache period. An accepted API request does not establish DNS propagation. B's lookup of A should fail while ping to A's private IP still succeeds. Reassociate B through reviewed Terraform repair, recheck DNS and connectivity, require no drift. Peering DNS options do not share an unassociated private zone.
- Missing private DNS record: save the exact A-record set, delete only `a.phase2.internal` through a reviewed Route 53 change batch, wait for `INSYNC` and beyond its positive/negative TTLs, then query with `dig` and `getent` from B. Require DNS failure while ping to A's private IP succeeds. Restore with a reviewed Terraform plan containing only that A-record creation, then repeat bidirectional baseline and require no drift. The SOA TTL and minimum are both 60 seconds for this disposable lab; wait until that SOA setting is active before deleting records. An older cached NXDOMAIN can outlive the restored A record. See the evidence record for whether the observed run met these criteria.
- Overlap: fixed nonoverlapping CIDRs are a design check, not a performed AWS failure drill. Never change CIDRs under a running lab for this exercise.

For each actual drill: symptom → hypothesis → evidence → root cause → fix → prevention, date, operator, sanitized output and limitations. If baseline is unhealthy, do not inject faults. No Flow Logs were added to this minimal phase; do not claim packet/log evidence without separately approved instrumentation.

## Cost and teardown

Billable full scope: four interface endpoint ENIs, two t3.micro instances, two 8-GiB gp3 volumes, one private hosted zone; possible data processing/transfer charges. CPU credits are set to standard to avoid surplus-credit billing. Same-AZ placement bounds transfer, tiny ping tests bound traffic. Do not assume Free Tier. Verify regional prices before approval using [PrivateLink](https://aws.amazon.com/privatelink/pricing/), [EC2](https://aws.amazon.com/ec2/pricing/on-demand/), [EBS](https://aws.amazon.com/ebs/pricing/) and [Route 53](https://aws.amazon.com/route53/pricing/). Hosted-zone monthly minimum/short-lived-zone billing rules must be included, not prorated by assumption. Disabling hosts alone leaves the zone; destroy the whole phase2 root.

```powershell
terraform plan -destroy -var='deploy_lab=true' -var='enable_test_hosts=true' '-out=destroy.tfplan'
terraform apply 'destroy.tfplan'
terraform state list
```

Verify terminated EC2 and removed volumes, deleted endpoints/ENIs, absent PHZ/records, deleted peering/VPCs/subnets/routes/SGs, and removed lab IAM profile/role/attachment through AWS APIs. Record failures and residual resources; empty state alone is insufficient. Review billing later because charges lag. If apply fails partway, inspect state and destroy only tracked phase2 resources; never delete unrelated account resources.

## Architecture comparison (design only)

Peering suits this two-VPC direct path but requires pairwise routes and does not transit. Transit Gateway offers hub/spoke routing at additional attachment/data cost; model only here. PrivateLink exposes a service rather than broad routed connectivity and can address overlapping consumer networks; the SSM endpoints use AWS PrivateLink but do not establish ownership of a custom endpoint service. Route 53 Resolver endpoints are for forwarding/hybrid DNS requirements and are unnecessary for a zone associated to both VPCs. None of these comparisons establish enterprise production tenure.

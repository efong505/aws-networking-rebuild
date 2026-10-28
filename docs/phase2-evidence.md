# Phase 2 evidence — 2026-10-27

## Current boundary

Source implementation only; no AWS resources created, no live network or DNS tests, no fault injection, and no Phase 2 teardown performed. Phase 1 evidence remains separate and complete with its documented qualifications.

## Gates

| Gate | Status |
|---|---|
| Terraform formatting | PASS — terraform fmt -recursive -check |
| Provider/schema validation | PASS — Terraform 1.14.6 / AWS provider 6.20.0 |
| Mocked topology tests | PASS — 3 tests; provider mocked, not live AWS validation |
| Account preflight and real plan | PASS — read-only plan: 28 add, 0 change, 0 destroy; ekewaka / us-west-2 |
| User cost approval / apply | Pending; no approval inferred |
| Bidirectional private IP + custom DNS checks | Not performed |
| Route/DNS fault and recovery | Not performed |
| Teardown and residual-resource checks | Not performed |

See [executable configuration and staged runbook](../terraform/phase2/README.md). Record actual results here after each gate; never convert proposed tests into accomplishments.

## Read-only preflight observations

Existing regional VPC count: 1; VPC quota: 5, leaving room for 2 lab VPCs. All associated IPv4 CIDRs checked numerically: no overlap with either lab /16. No existing phase2.internal hosted zone. Real plan resource types/counts match the 28-resource runbook inventory. Raw plan/output remains local and ignored. This does not prove create permissions, EC2 capacity, every service quota or working runtime connectivity. Account selection must be confirmed privately before apply.

## Local verification qualification

The Windows environment's local Terraform/provider mutual TLS handshake failed with an unknown certificate authority. Local validate/test and the read-only plan succeeded with process-scoped TF_DISABLE_PLUGIN_TLS=1. This affects Terraform's local provider RPC channel; AWS HTTPS certificate verification was not disabled. Do not persist the workaround globally. AWS provider is pinned to the tested 6.20.0 with its committed lock file. Mock tests perform no AWS operations, including the mock apply/teardown test.

A real plan has been produced but not applied. Refresh it if code, credentials, inputs or the approved session change. Cost approval and the named teardown window remain the next gate.

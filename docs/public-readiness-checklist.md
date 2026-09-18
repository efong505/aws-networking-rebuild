# Employer-Facing Public-Readiness Checklist

Run this before changing the repository from private to public or featuring it on the GitHub profile.

## Accessibility and status

- [ ] Default branch is current.
- [ ] README renders correctly.
- [ ] `IMPLEMENTATION_STATUS.md` matches actual performed work.
- [ ] Planned Phase 2 work is clearly labeled planned.

## Security and privacy

- [ ] No credentials, tokens, private keys, or secrets.
- [ ] No AWS account IDs in committed evidence.
- [ ] No Terraform state files.
- [ ] No populated environment-specific `.tfvars`.
- [ ] No employer/customer/private business data.
- [ ] No unsanitized screenshots or CLI output.

## Evidence integrity

- [ ] Implemented work is supported by committed validation notes.
- [ ] Lab/project evidence is labeled as such.
- [ ] No professional-production AWS tenure is implied.
- [ ] No certification claim is made unless the credential is earned.
- [ ] Transit Gateway or other Phase 2 items are not described as implemented unless performed.

## Employer readability

- [ ] Problem/objective is clear.
- [ ] Architecture is easy to understand.
- [ ] Technologies are obvious.
- [ ] Implemented vs planned state is obvious.
- [ ] Security/reliability decisions are explained.
- [ ] Validation/testing is visible.
- [ ] Troubleshooting/failure handling is visible.
- [ ] Safe reproduction/teardown steps exist.
- [ ] “What this demonstrates” section is accurate.

## Repository hygiene

- [ ] No generated clutter at repository root.
- [ ] No duplicate or stale README sections.
- [ ] No obsolete evidence files that contradict current state.
- [ ] Resource naming is generic and employer-safe.

# Security and Public-Evidence Policy

This is intended to become an employer-facing public repository after a separate public-readiness review.

## Never commit

- AWS access keys, session tokens, passwords, or credentials of any kind;
- AWS account IDs in evidence captures;
- Terraform state files;
- populated `terraform.tfvars` or other environment-specific secret/configuration files;
- raw AWS CLI output that has not been reviewed and sanitized;
- screenshots showing account-identifying navigation, billing data, personal data, or unrelated resources;
- employer/customer/internal infrastructure information;
- private keys or SSH material.

## Evidence rule

Sanitized evidence should demonstrate the engineering decision or validation result without exposing more environment detail than necessary.

When in doubt, record a concise Markdown observation instead of committing raw console/CLI output.

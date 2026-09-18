# Interview Explain-Backs

Use these after performing the corresponding implementation/validation. The goal is to explain from understanding, not memorize scripts.

## Public vs private subnet

Explain why a subnet is not “public” merely because a resource has a public IP, and how the associated route table and Internet Gateway path affect the design.

## Private IPv4 egress

Explain how a private EC2 instance reaches the public internet through a NAT Gateway and why the NAT Gateway itself resides in a public subnet.

## Gateway vs Interface VPC Endpoint

Explain why the S3 endpoint in this project is route-table based while Systems Manager endpoints use ENIs, private DNS, and security groups.

## Security Group vs NACL

Explain stateful allow-only security groups versus stateless ordered NACL allow/deny rules and how that affects return traffic troubleshooting.

## Flow Logs

Explain what VPC Flow Logs can show during troubleshooting and what they do not prove by themselves.

## Failure story

For each performed drill, be able to describe:

**symptom → hypothesis → evidence → root cause → fix → prevention**

Do not present a controlled lab failure as a professional production incident.

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "= 6.20.0"
    }
  }
}

variable "aws_region" {
  type    = string
  default = "us-west-2"
}

variable "deploy_lab" {
  description = "Enable only after user approves the reviewed plan, budget and teardown window."
  type        = bool
  default     = false
}

variable "enable_test_hosts" {
  description = "Creates two billable EC2 hosts and four SSM interface endpoints."
  type        = bool
  default     = false
}

variable "owner" {
  type    = string
  default = "lab-owner"
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Project     = "aws-networking-phase2"
      Environment = "lab"
      ManagedBy   = "Terraform"
      Owner       = var.owner
    }
  }
}

locals {
  networks = var.deploy_lab ? {
    a = { cidr = "10.52.0.0/16", subnet = "10.52.1.0/24" }
    b = { cidr = "10.53.0.0/16", subnet = "10.53.1.0/24" }
  } : {}
  hosts = var.enable_test_hosts ? local.networks : {}
  endpoints = { for pair in setproduct(keys(local.hosts), ["ssm", "ssmmessages"]) :
    "${pair[0]}-${pair[1]}" => { network = pair[0], service = pair[1] }
  }
}

resource "aws_vpc" "lab" {
  for_each             = local.networks
  cidr_block           = each.value.cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "phase2-${each.key}" }
}

resource "aws_subnet" "private" {
  for_each                = local.networks
  vpc_id                  = aws_vpc.lab[each.key].id
  cidr_block              = each.value.subnet
  availability_zone       = data.aws_availability_zones.available[0].names[0]
  map_public_ip_on_launch = false
  tags                    = { Name = "phase2-${each.key}-private" }
}

data "aws_availability_zones" "available" {
  count = var.deploy_lab ? 1 : 0
  state = "available"
}

resource "aws_route_table" "private" {
  for_each = local.networks
  vpc_id   = aws_vpc.lab[each.key].id
  tags     = { Name = "phase2-${each.key}-private" }
}

resource "aws_route_table_association" "private" {
  for_each       = local.networks
  subnet_id      = aws_subnet.private[each.key].id
  route_table_id = aws_route_table.private[each.key].id
}

resource "aws_vpc_peering_connection" "lab" {
  count       = var.deploy_lab ? 1 : 0
  vpc_id      = aws_vpc.lab["a"].id
  peer_vpc_id = aws_vpc.lab["b"].id
  auto_accept = true
  tags        = { Name = "phase2-a-b" }
}

resource "aws_vpc_peering_connection_options" "dns" {
  count                     = var.deploy_lab ? 1 : 0
  vpc_peering_connection_id = aws_vpc_peering_connection.lab[0].id
  requester { allow_remote_vpc_dns_resolution = true }
  accepter { allow_remote_vpc_dns_resolution = true }
}

resource "aws_route" "peer" {
  for_each                  = local.networks
  route_table_id            = aws_route_table.private[each.key].id
  destination_cidr_block    = local.networks[each.key == "a" ? "b" : "a"].cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.lab[0].id
}

resource "aws_security_group" "host" {
  for_each    = local.hosts
  name_prefix = "phase2-${each.key}-host-"
  vpc_id      = aws_vpc.lab[each.key].id
  ingress {
    description = "ICMP echo from peer subnet for bounded connectivity validation"
    protocol    = "icmp"
    from_port   = 8
    to_port     = -1
    cidr_blocks = [local.networks[each.key == "a" ? "b" : "a"].subnet]
  }
  egress {
    description = "ICMP to peer subnet"
    protocol    = "icmp"
    from_port   = -1
    to_port     = -1
    cidr_blocks = [local.networks[each.key == "a" ? "b" : "a"].subnet]
  }
  egress {
    description = "SSM HTTPS inside this VPC only"
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [each.value.cidr]
  }
}

resource "aws_security_group" "endpoint" {
  for_each    = local.hosts
  name_prefix = "phase2-${each.key}-endpoint-"
  vpc_id      = aws_vpc.lab[each.key].id
  ingress {
    description     = "SSM HTTPS from local test host"
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    security_groups = [aws_security_group.host[each.key].id]
  }
}

resource "aws_vpc_endpoint" "ssm" {
  for_each            = local.endpoints
  vpc_id              = aws_vpc.lab[each.value.network].id
  service_name        = "com.amazonaws.${var.aws_region}.${each.value.service}"
  vpc_endpoint_type   = "Interface"
  subnet_ids          = [aws_subnet.private[each.value.network].id]
  security_group_ids  = [aws_security_group.endpoint[each.value.network].id]
  private_dns_enabled = true
}

resource "aws_iam_role" "host" {
  count       = length(local.hosts) > 0 ? 1 : 0
  name_prefix = "phase2-ssm-"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [{ Effect = "Allow", Action = "sts:AssumeRole", Principal = { Service = "ec2.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  count      = length(local.hosts) > 0 ? 1 : 0
  role       = aws_iam_role.host[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "host" {
  count       = length(local.hosts) > 0 ? 1 : 0
  name_prefix = "phase2-ssm-"
  role        = aws_iam_role.host[0].name
}

data "aws_ssm_parameter" "ami" {
  count = length(local.hosts) > 0 ? 1 : 0
  name  = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "host" {
  for_each                    = local.hosts
  ami                         = data.aws_ssm_parameter.ami[0].value
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private[each.key].id
  vpc_security_group_ids      = [aws_security_group.host[each.key].id]
  iam_instance_profile        = aws_iam_instance_profile.host[0].name
  associate_public_ip_address = false
  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }
  credit_specification {
    cpu_credits = "standard"
  }
  root_block_device {
    encrypted             = true
    volume_size           = 8
    volume_type           = "gp3"
    delete_on_termination = true
  }
  tags       = { Name = "phase2-${each.key}-private-test" }
  depends_on = [aws_iam_role_policy_attachment.ssm, aws_vpc_endpoint.ssm]
}

# PHZ associations are separate from the peering DNS-resolution options.
resource "aws_route53_zone" "lab" {
  count = var.deploy_lab ? 1 : 0
  name  = "phase2.internal"
  vpc { vpc_id = aws_vpc.lab["a"].id }
  vpc { vpc_id = aws_vpc.lab["b"].id }
}

resource "aws_route53_record" "host" {
  for_each = local.hosts
  zone_id  = aws_route53_zone.lab[0].zone_id
  name     = "${each.key}.phase2.internal"
  type     = "A"
  ttl      = 30
  records  = [aws_instance.host[each.key].private_ip]
}

output "validation_targets" {
  value = {
    for key, host in aws_instance.host : key => {
      instance_id = host.id
      private_ip  = host.private_ip
      private_dns = host.private_dns
      test_name   = aws_route53_record.host[key].fqdn
    }
  }
}

output "route_tables" {
  value = { for key, table in aws_route_table.private : key => table.id }
}

output "peering_id" {
  value = try(aws_vpc_peering_connection.lab[0].id, null)
}

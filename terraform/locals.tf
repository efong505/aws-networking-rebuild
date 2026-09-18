locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)

  common_name = var.project_name

  ssm_endpoint_services = toset([
    "ssm",
    "ssmmessages"
  ])
}

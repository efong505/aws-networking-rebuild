variable "aws_region" {
  description = "AWS Region for the lab."
  type        = string
  default     = "us-west-2"
}

variable "project_name" {
  description = "Resource naming prefix."
  type        = string
  default     = "aws-networking-rebuild"
}

variable "vpc_cidr" {
  description = "Primary VPC CIDR."
  type        = string
  default     = "10.42.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "Two public subnet CIDRs, one per AZ."
  type        = list(string)
  default     = ["10.42.0.0/24", "10.42.1.0/24"]

  validation {
    condition     = length(var.public_subnet_cidrs) == 2
    error_message = "Provide exactly two public subnet CIDRs."
  }
}

variable "private_subnet_cidrs" {
  description = "Two private subnet CIDRs, one per AZ."
  type        = list(string)
  default     = ["10.42.10.0/24", "10.42.11.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) == 2
    error_message = "Provide exactly two private subnet CIDRs."
  }
}

variable "enable_nat_gateways" {
  description = "Create one NAT Gateway per AZ for temporary IPv4 egress validation. Incurs cost."
  type        = bool
  default     = false
}

variable "enable_test_instance" {
  description = "Create one private Amazon Linux validation instance managed with Systems Manager. Incurs cost."
  type        = bool
  default     = false
}

variable "flow_log_retention_days" {
  description = "CloudWatch retention for VPC Flow Logs."
  type        = number
  default     = 7
}

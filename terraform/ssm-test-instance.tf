resource "aws_iam_role" "ssm_instance" {
  name = "${local.common_name}-ssm-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ssm_core" {
  role       = aws_iam_role.ssm_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ssm" {
  name = "${local.common_name}-ssm-instance-profile"
  role = aws_iam_role.ssm_instance.name
}

resource "aws_security_group" "test_instance" {
  name        = "${local.common_name}-test-instance-sg"
  description = "Private validation instance; no inbound rules"
  vpc_id      = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${local.common_name}-test-instance-sg"
  }
}

data "aws_ssm_parameter" "al2023_ami" {
  count = var.enable_test_instance ? 1 : 0

  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_instance" "test" {
  count = var.enable_test_instance ? 1 : 0

  ami                    = data.aws_ssm_parameter.al2023_ami[0].value
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.private[0].id
  vpc_security_group_ids = [aws_security_group.test_instance.id]
  iam_instance_profile   = aws_iam_instance_profile.ssm.name

  associate_public_ip_address = false

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = {
    Name = "${local.common_name}-private-test"
  }
}

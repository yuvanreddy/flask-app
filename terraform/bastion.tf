############################################
# SSM Bastion EC2 (private subnet)
############################################

resource "aws_iam_role" "bastion_ssm_role" {
  name               = "bastion-ssm-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }
    ]
  })
  tags = { Project = var.project_name }
}

resource "aws_iam_role_policy_attachment" "bastion_ssm_core" {
  role       = aws_iam_role.bastion_ssm_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "bastion" {
  name = "bastion-ssm-instance-profile"
  role = aws_iam_role.bastion_ssm_role.name
}

resource "aws_security_group" "bastion" {
  name        = "${var.project_name}-bastion-sg"
  description = "Bastion SG (no inbound, SSM only)"
  vpc_id      = module.vpc.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Project = var.project_name }
}

# Pick first private subnet for the instance
resource "aws_instance" "bastion" {
  ami                    = data.aws_ami.amazon_linux2.id
  instance_type          = "t3.micro"
  subnet_id              = module.vpc.private_subnets[0]
  vpc_security_group_ids = [aws_security_group.bastion.id]
  iam_instance_profile   = aws_iam_instance_profile.bastion.name
  associate_public_ip_address = false

  tags = {
    Name    = "${var.project_name}-bastion"
    Project = var.project_name
  }
}

# Latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux2" {
  owners      = ["137112412989"] # Amazon
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

output "bastion_instance_id" { value = aws_instance.bastion.id }

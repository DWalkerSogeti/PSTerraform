##################################################################################
# DATA
##################################################################################

data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/amzn2-ami-hvm-x86_64-gp2"
}

data "aws_availability_zones" "available" {
  state = "available"
}

##################################################################################
# RESOURCES
##################################################################################

# NETWORKING #

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "=3.14.0"

  cidr = var.vpc_cidr_block

  azs             = slice(data.aws_availability_zones.available.names,0,(var.vpc_subnet_count))
  public_subnets  = [ for subnet in range(var.vpc_subnet_count) : cidrsubnet(var.vpc_cidr_block, 8, subnet) ]

  enable_nat_gateway = false ## We dont have any private gateways
  enable_vpn_gateway = false ## We dont have any vpn gateways

## Adding these tags from our existing VPC resource block
  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-vpc"
  })
}

## With our new VPC module, we can remove the other networking resources

# SECURITY GROUPS #
# Nginx security group 
resource "aws_security_group" "nginx-sg" {
  name   = "${local.name_prefix}-nginx_sg"
  vpc_id = module.vpc.vpc_id ## Updating this to ref. the new module

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr_block]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

resource "aws_security_group" "alb_sg" {
  name   = "${local.name_prefix}-nginx_alb_sg"
  vpc_id = aws_vpc.vpc.id

  # HTTP access from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = local.common_tags
}

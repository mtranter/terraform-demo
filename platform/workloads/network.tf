locals {
  environment = terraform.workspace
}


#tfsec:ignore:aws-ec2-no-public-ingress-acl tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "${var.vpc_name}-${local.environment}"
  cidr = var.vpc_cidr_block

  azs              = slice(data.aws_availability_zones.available.names, 0, 3)
  private_subnets  = var.private_subnet_cidr_blocks
  public_subnets   = var.public_subnet_cidr_blocks
  database_subnets = var.database_subnet_cidr_blocks

  enable_nat_gateway   = true
  enable_vpn_gateway   = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # ACLs

  #-----------------------------------------------------------------------#
  # Public ACLs
  #-----------------------------------------------------------------------#

  public_dedicated_network_acl = true
  public_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
      }, {
      rule_number = 200
      rule_action = "allow"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
  }]
  public_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
  }]

  #-----------------------------------------------------------------------#
  # Private ACLs
  #-----------------------------------------------------------------------#

  private_dedicated_network_acl = true
  private_inbound_acl_rules = [
    for sn in var.public_subnet_cidr_blocks :
    {
      rule_number = index(var.var.public_subnet_cidr_blocks, sn) * 100 + 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "tcp"
      cidr_block  = sn
    }
  ]
  private_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
  }]

  #-----------------------------------------------------------------------#
  # Database ACLs
  #-----------------------------------------------------------------------#

  database_dedicated_network_acl = true
  database_inbound_acl_rules = [
    for sn in var.private_subnet_cidr_blocks :
    {
      rule_number = index(var.var.private_subnet_cidr_blocks, sn) * 100 + 100
      rule_action = "allow"
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_block  = sn
    }
  ]
  database_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      from_port   = 0
      to_port     = 0
      protocol    = "tcp"
      cidr_block  = "0.0.0.0/0"
  }]
}

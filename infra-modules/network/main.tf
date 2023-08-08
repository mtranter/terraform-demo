variable "region" {
  type = string
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "cidr_block" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "subnet_definitions" {
  type = map(object({
    new_bits  = number
    is_public = bool
  }))
}

variable "nacls" {
  type = list(object({
    name    = string
    subnets = list(string)
    ingress = list(object({
      protocol   = string
      rule_no    = number
      action     = string
      cidr_block = string
      from_port  = number
      to_port    = number
    }))
    egress = list(object({
      protocol   = string
      rule_no    = number
      action     = string
      cidr_block = string
      from_port  = number
      to_port    = number
    }))
  }))
}

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 3)
  subnet_azs = flatten(
    [for k, s in var.subnet_definitions :
      [for az in local.azs :
        {
          name      = "${k}-${data.aws_availability_zone.azs[index(local.azs, az)].name_suffix}", // e.g. "public-a"
          az        = az,
          is_public = s.is_public,
          new_bits  = s.new_bits
        }
      ]
    ]
  )
  nacl_subnet_az = flatten([
    for n in var.nacls : [
      for s in n.subnets : [
        for az in local.azs : {
          nane        = n.name
          subnet_name = "${s}-${data.aws_availability_zone.azs[index(local.azs, az)].name_suffix}"
          is_public   = sa.is_public
          new_bits    = sa.new_bits
          nacls       = sa.nacls
        }
      ]
    ]
  ])
}

provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}
data "aws_availability_zone" "azs" {
  count = length(local.azs)
  name  = local.azs[count.index]
}

module "subnet_definitions" {
  source          = "hashicorp/subnets/cidr"
  base_cidr_block = var.cidr_block
  networks        = [for s in local.subnet_azs : { name = s.name, new_bits = s.new_bits }]
}

resource "aws_vpc" "vpc" {
  cidr_block = var.cidr_block
  tags = {
    Name = var.vpc_name
  }
}

resource "aws_subnet" "subnet" {
  for_each          = { for s in local.subnet_azs : s.name => s }
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = module.subnet_definitions.network_cidr_blocks[each.key]
  availability_zone = each.value.az

  tags = {
    Name = each.key
  }
}

resource "aws_network_acl" "nacl" {
  for_each = { for n in var.nacls : n.name => n }
  vpc_id   = aws_vpc.vpc.id
  tags = {
    Name = each.key
  }
}

resource "aws_network_acl_rule" "ingress_rules" {
  for_each = flatten([
    for n in var.nacls : [
      for r in n.ingress : {
        name = n.name
        rule = r
      }
    ]
  ])
  network_acl_id = aws_network_acl.nacl[each.value.name].id
  rule_no        = each.value.rule_no
  protocol       = each.value.rule.protocol
  rule_action    = each.value.rule.action
  cidr_block     = each.value.rule.cidr_block
  from_port      = each.value.rule.from_port
  to_port        = each.value.rule.to_port
  egress         = false
}


resource "aws_network_acl_rule" "egress_rules" {
  for_each = flatten([
    for n in var.nacls : [
      for r in n.egress : {
        name = n.name
        rule = r
      }
    ]
  ])
  network_acl_id = aws_network_acl.nacl[each.value.name].id
  rule_no        = each.value.rule_no
  protocol       = each.value.rule.protocol
  rule_action    = each.value.rule.action
  cidr_block     = each.value.rule.cidr_block
  from_port      = each.value.rule.from_port
  to_port        = each.value.rule.to_port
  egress         = true
}

resource "aws_network_acl_associations" "associations" {
  for_each = local.nacl_subnet_az
  subnet_id      = aws_subnet.subnet[each.value.subnet_name].id
  network_acl_id = aws_network_acl.nacl[each.value.name].id
}

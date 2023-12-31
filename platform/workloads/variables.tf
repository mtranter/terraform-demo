variable "provider_role_arn" {
  type = string
}

variable "region" {
  type = string
}   

variable "vpc_name" {
  type = string
}

variable "vpc_cidr_block" {
  type = string
}

variable "private_subnet_cidr_blocks" {
  type = list(string)
}

variable "public_subnet_cidr_blocks" {
  type = list(string)
}

variable "database_subnet_cidr_blocks" {
  type = list(string)
}

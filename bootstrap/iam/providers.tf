provider "aws" {
  region = var.region
}


data "aws_ssm_parameter" "prod_account_id" {
  name     = "/accounts/workloads/production/id"
}

data "aws_ssm_parameter" "nonprod_account_id" {
  name     = "/accounts/workloads/nonproduction/id"
}

provider "aws" {
  alias  = "nonprod"
  region = var.region
  assume_role {
    role_arn = "arn:aws:iam::${data.aws_ssm_parameter.nonprod_account_id.value}:role/OrganizationAccountAccessRole"
  }
}


provider "aws" {
  alias  = "prod"
  region = var.region
  assume_role {
    role_arn = "arn:aws:iam::${data.aws_ssm_parameter.prod_account_id.value}:role/OrganizationAccountAccessRole"
  }
}

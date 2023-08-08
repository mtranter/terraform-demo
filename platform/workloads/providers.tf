provider "aws" {
  region = var.region
  assume_role {
    role_arn = var.provider_role_arn
  }
}

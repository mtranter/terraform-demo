variable "region" {
  type = string
}

variable "openid_provider_url" {
  type        = string
  description = "OpenID Connect Provider URL"
}

variable "openid_thumbprint" {
  type        = string
  description = "OpenID Connect Provider Thumbprint"
}

variable "git_org" {
  type = string
}

variable "git_repo" {
  type = string
}

variable "git_trunk_branch" {
  type = string
}
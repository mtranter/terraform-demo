variable "admin_email_address" {
  type        = string
  description = "Email address of the admin user"
}

variable "workload_allowed_regions" {
  type        = set(string)
  description = "List of regions allowed for workloads"
}

variable "workload_accounts" {
  type        = set(string)
  description = "List of accounts to create for workloads, e.g. [\"nonproduction\", \"production\"]"
}

variable "cross_account_deployer_role_name" {
  type        = string
  description = "Name of the cross account deployer role"
  default     = "OrganizationAccountAccessRole"
}

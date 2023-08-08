# AWS Organizations Terraform Module

This module is used to provision resources related to AWS Organizations, including the creation of an AWS organization, organizational units, accounts, service control policies, IAM roles, and SSM parameters. This module assumes a best practice setup for multiple environments like "nonproduction" and "production".

## Features

- Sets up an AWS Organization with specific AWS service access principals.
- Creates organizational units.
- Creates accounts under the 'workloads' organizational unit.
- Attaches a service control policy that denies all actions outside a specified set of AWS regions.
- Grants the module caller permissions to assume a cross-account role in each created account.
- Stores the ARN of the role to be assumed in SSM parameters.


## Setup
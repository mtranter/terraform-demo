

locals {
  workload_accounts          = toset(["nonproduction", "production"])
  admin_email_address_user   = split("@", var.admin_email_address)[0]
  admin_email_address_domain = split("@", var.admin_email_address)[1]
}

resource "aws_organizations_organization" "org" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "detective.amazonaws.com",
    "guardduty.amazonaws.com",
    "inspector2.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com",
  ]

  feature_set          = "ALL"
  enabled_policy_types = ["SERVICE_CONTROL_POLICY", "TAG_POLICY", "BACKUP_POLICY", "AISERVICES_OPT_OUT_POLICY"]
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "workloads"
  parent_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_account" "account" {
  for_each          = local.workload_accounts
  name              = each.value
  email             = "${local.admin_email_address_user}+${each.value}@${local.admin_email_address_domain}"
  close_on_deletion = true
  parent_id         = aws_organizations_organizational_unit.workloads.id
  role_name         = var.cross_account_deployer_role_name
}

// region scp
resource "aws_organizations_policy" "workloads_scp" {
  name        = "workloads_scp"
  description = "Workloads SCP"
  type        = "SERVICE_CONTROL_POLICY"

  content = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "DenyAllOutsideEU",
            "Effect": "Deny",
            "NotAction": [
                "a4b:*",
                "acm:*",
                "aws-marketplace-management:*",
                "aws-marketplace:*",
                "aws-portal:*",
                "budgets:*",
                "ce:*",
                "chime:*",
                "cloudfront:*",
                "config:*",
                "cur:*",
                "directconnect:*",
                "ec2:DescribeRegions",
                "ec2:DescribeTransitGateways",
                "ec2:DescribeVpnGateways",
                "fms:*",
                "globalaccelerator:*",
                "health:*",
                "iam:*",
                "importexport:*",
                "kms:*",
                "mobileanalytics:*",
                "networkmanager:*",
                "organizations:*",
                "pricing:*",
                "route53:*",
                "route53domains:*",
                "route53-recovery-cluster:*",
                "route53-recovery-control-config:*",
                "route53-recovery-readiness:*",
                "s3:GetAccountPublic*",
                "s3:ListAllMyBuckets",
                "s3:ListMultiRegionAccessPoints",
                "s3:PutAccountPublic*",
                "shield:*",
                "sts:*",
                "support:*",
                "trustedadvisor:*",
                "waf-regional:*",
                "waf:*",
                "wafv2:*",
                "wellarchitected:*"
            ],
            "Resource": "*",
            "Condition": {
                "StringNotEquals": {
                    "aws:RequestedRegion": ${jsonencode(var.workload_allowed_regions)}
                }
            }
        }
    ]
}
EOF
}

resource "aws_organizations_policy_attachment" "workloads_scp_attachment" {
  for_each  = local.workload_accounts
  policy_id = aws_organizations_policy.workloads_scp.id
  target_id = aws_organizations_account.account[each.key].id
}

data "aws_caller_identity" "current" {}

resource "aws_iam_policy" "workloads_assume_role" {
  name        = "workloads-admin-assume-role"
  description = "Allow current user to assume admin role in workload accounts"
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AllowAssumeRole",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource":
                ${trim(jsonencode([for account in aws_organizations_account.account : "arn:aws:iam::${account.id}:role/${var.cross_account_deployer_role_name}"]), ",")}
        }
    ]
}
EOF
}


resource "aws_iam_user_policy_attachment" "workloads_assume_role_attachment" {
  user       = split("/", data.aws_caller_identity.current.arn)[1]
  policy_arn = aws_iam_policy.workloads_assume_role.arn
}

resource "aws_ssm_parameter" "workload_role" {
  for_each = local.workload_accounts
  name     = "/accounts/workloads/${each.key}/role-arn"
  type     = "String"
  value    = "arn:aws:iam::${aws_organizations_account.account[each.key].id}:role/${var.cross_account_deployer_role_name}"
}


resource "aws_ssm_parameter" "workload_account_ids" {
  for_each = local.workload_accounts
  name     = "/accounts/workloads/${each.key}/id"
  type     = "String"
  value    = aws_organizations_account.account[each.key].id
}

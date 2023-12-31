data "aws_caller_identity" "mgmt" {}

locals {
  github_depoloyer_mgmt_policies = [
    "arn:aws:iam::aws:policy/AmazonS3FullAccess",
    "arn:aws:iam::aws:policy/AmazonSSMReadOnlyAccess",
  ]
}

resource "aws_iam_openid_connect_provider" "openid_provider" {
  url = var.openid_provider_url

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [var.openid_thumbprint]
}

resource "aws_iam_role" "github_actions_deployer" {
  name               = "github-actions-deployer"
  description        = "GitHub SSO policy"
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "This",
            "Effect": "Allow",
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Principal": {
                "Federated": "arn:aws:iam::${data.aws_caller_identity.mgmt.account_id}:oidc-provider/token.actions.githubusercontent.com"
            },
            "Condition": {
                "StringEquals": {
                  "token.actions.githubusercontent.com:aud": "sts.amazonaws.com",
                  "token.actions.githubusercontent.com:sub": "repo:${var.git_org}/${var.git_repo}:ref:refs/heads/${var.git_trunk_branch}"
                }
            }
        }
    ]
}
EOF
}

## Allow github-actions-deployer to assume roles in workload accounts
resource "aws_iam_role_policy" "github_can_deploy_to_workloads" {
  name = "github-can-deploy-to-workloads"
  role = aws_iam_role.github_actions_deployer.id

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "This",
            "Effect": "Allow",
            "Action": "sts:AssumeRole",
            "Resource": [
              "arn:aws:iam::${data.aws_ssm_parameter.nonprod_account_id.value}:role/workload-depoyler-nonprod",
              "arn:aws:iam::${data.aws_ssm_parameter.prod_account_id.value}:role/workload-depoyler-prod"
            ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "github_actions_deployer_mgmt_policies" {
  for_each   = toset(local.github_depoloyer_mgmt_policies)
  role       = aws_iam_role.github_actions_deployer.name
  policy_arn = each.value
}

resource "aws_iam_role" "nonprod_deployer" {
  provider           = aws.nonprod
  name               = "workload-depoyler-nonprod"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "This",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${data.aws_caller_identity.mgmt.account_id}:root"
        ]
      },
      "Condition": {
        "StringEquals": {
          "aws:PrincipalArn": "arn:aws:iam::${data.aws_caller_identity.mgmt.account_id}:role/github-actions-deployer"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "nonprod_github_actions_deployer" {
  provider   = aws.nonprod
  role       = aws_iam_role.nonprod_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}


resource "aws_iam_role" "prod_deployer" {
  provider           = aws.prod
  name               = "workload-depoyler-prod"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "This",
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": [
          "arn:aws:iam::${data.aws_caller_identity.mgmt.account_id}:root"
        ]
      },
      "Condition": {
        "StringEquals": {
          "aws:PrincipalArn": "arn:aws:iam::${data.aws_caller_identity.mgmt.account_id}:role/github-actions-deployer"
        }
      }
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "prod_github_actions_deployer" {
  provider   = aws.prod
  role       = aws_iam_role.prod_deployer.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

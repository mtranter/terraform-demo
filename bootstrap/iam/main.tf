data "aws_caller_identity" "mgmt" {}

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

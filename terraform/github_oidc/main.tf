# AWS ko batao ki GitHub Actions ke tokens par bharosa karna hai
resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]
}


locals {
  github_repo = "Dhiraj-Mantri/serverless-devsecops-pipeline"
}

# Trust policy: kaun is role ko pehen sakta hai? Sirf hamare repo ka GitHub token
data "aws_iam_policy_document" "github_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${local.github_repo}:*"]
    }
  }
}

# Role khud (abhi iske paas koi permission nahi hai)
resource "aws_iam_role" "github_actions" {
  name               = "github-actions-terraform"
  assume_role_policy = data.aws_iam_policy_document.github_assume.json
}



locals {
  state_bucket = "tfstate-206465504961-eu-north-1"
}

# Permission 1: Terraform state padhna/likhna (sirf serverless-api/ wala hissa)
data "aws_iam_policy_document" "state_access" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = ["arn:aws:s3:::${local.state_bucket}"]
  }

  statement {
    sid       = "ReadWriteAppState"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["arn:aws:s3:::${local.state_bucket}/serverless-api/*"]
  }
}

resource "aws_iam_role_policy" "state_access" {
  name   = "terraform-state-access"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.state_access.json
}



data "aws_caller_identity" "current" {}

locals {
  account_id  = data.aws_caller_identity.current.account_id
  region      = "eu-north-1"
  name_prefix = "items-api-*"
}

# Permission 2: DynamoDB aur Lambda banana/badalna/hatana (sirf items-api-* naam wale)
data "aws_iam_policy_document" "app_compute" {
  statement {
    sid = "ManageAppTable"
    actions = [
      "dynamodb:CreateTable",
      "dynamodb:DeleteTable",
      "dynamodb:UpdateTable",
      "dynamodb:DescribeTable",
      "dynamodb:DescribeContinuousBackups",
      "dynamodb:UpdateContinuousBackups",
      "dynamodb:DescribeTimeToLive",
      "dynamodb:UpdateTimeToLive",
      "dynamodb:DescribeKinesisStreamingDestination",
      "dynamodb:ListTagsOfResource",
      "dynamodb:TagResource",
      "dynamodb:UntagResource",
    ]
    resources = ["arn:aws:dynamodb:${local.region}:${local.account_id}:table/${local.name_prefix}"]
  }

  statement {
    sid       = "ManageAppFunction"
    actions   = ["lambda:*"]
    resources = ["arn:aws:lambda:${local.region}:${local.account_id}:function:${local.name_prefix}"]
  }
}

resource "aws_iam_role_policy" "app_compute" {
  name   = "app-dynamodb-lambda"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.app_compute.json
}


# Permission 3: Lambda ka IAM role banana (sirf items-api-* naam wale roles)
data "aws_iam_policy_document" "app_iam" {
  statement {
    sid = "ManageAppRole"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:UpdateAssumeRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:ListRoleTags",
      "iam:PutRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:ListRolePolicies",
      "iam:ListAttachedRolePolicies",
      "iam:ListInstanceProfilesForRole",
    ]
    resources = ["arn:aws:iam::${local.account_id}:role/${local.name_prefix}"]
  }

  statement {
    sid       = "PassRoleToLambdaOnly"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${local.account_id}:role/${local.name_prefix}"]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "app_iam" {
  name   = "app-iam-role"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.app_iam.json
}


# Permission 4: CloudWatch log group aur API Gateway
data "aws_iam_policy_document" "app_edge" {
  statement {
    sid = "ManageAppLogGroup"
    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:PutRetentionPolicy",
      "logs:DeleteRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource",
      "logs:ListTagsForResource",
      "logs:ListTagsLogGroup",
    ]
    resources = [
      "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${local.name_prefix}",
      "arn:aws:logs:${local.region}:${local.account_id}:log-group:/aws/lambda/${local.name_prefix}:*",
    ]
  }

  statement {
    sid       = "DescribeLogGroups"
    actions   = ["logs:DescribeLogGroups"]
    resources = ["*"]
  }

  statement {
    sid     = "ManageHttpApi"
    actions = ["apigateway:GET", "apigateway:POST", "apigateway:PUT", "apigateway:PATCH", "apigateway:DELETE", "apigateway:TagResource"]
    resources = [
      "arn:aws:apigateway:${local.region}::/apis",
      "arn:aws:apigateway:${local.region}::/apis/*",
      "arn:aws:apigateway:${local.region}::/tags/*",
    ]
  }
}

resource "aws_iam_role_policy" "app_edge" {
  name   = "app-logs-apigateway"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.app_edge.json
}

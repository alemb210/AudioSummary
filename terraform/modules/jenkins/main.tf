#Module for provisioning an IAM user for Jenkins with specific permissions
data "aws_caller_identity" "current" {}

resource "aws_iam_user" "jenkins_user" {
  name = var.user_name
}

data "aws_iam_policy_document" "jenkins_policy_doc" {
  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::${var.s3_bucket_name}/*"
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "cloudfront:CreateInvalidation"
    ]
    resources = [
      var.cloudfront_distribution_arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "iam:ListAccessKeys",
      "iam:GetAccessKeyLastUsed",
      "iam:DeleteAccessKey",
      "iam:CreateAccessKey",
      "iam:UpdateAccessKey"
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.user_name}"
    ]
  }

}

resource "aws_iam_policy" "jenkins_policy" {
  name   = "${var.user_name}-policy"
  policy = data.aws_iam_policy_document.jenkins_policy_doc.json
}

resource "aws_iam_user_policy_attachment" "jenkins_policy_attachment" {
  user       = aws_iam_user.jenkins_user.name
  policy_arn = aws_iam_policy.jenkins_policy.arn
}


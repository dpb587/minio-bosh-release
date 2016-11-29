variable "release_repo"   { default = "minio-bosh-release" }
variable "release_owner"  { default = "dpb587" }
variable "region"         { default = "us-east-1" }
variable "ssh_public_key" { }

output "aws_access_key" { value = "${aws_iam_access_key.user.id}" }
output "aws_secret_key" { value = "${aws_iam_access_key.user.secret}" }

provider "aws" {
  region = "${var.region}"
}

#
# iam
#

resource "aws_iam_user" "user" {
    name = "${var.release_repo}"
}

resource "aws_iam_access_key" "user" {
    user = "${aws_iam_user.user.name}"
}

#
# s3
#

resource "aws_s3_bucket" "bucket" {
    bucket = "${var.release_owner}-${var.release_repo}-${var.region}"
    versioning {
        enabled = true
    }
}

data "aws_iam_policy_document" "bucket" {
  statement {
    actions = [
      "s3:GetObject",
    ]
    effect = "Allow"
    principals {
      type = "*"
      identifiers = ["*"]
    }
    resources = [
      "${aws_s3_bucket.bucket.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "bucket" {
  bucket = "${aws_s3_bucket.bucket.id}"
  policy = "${data.aws_iam_policy_document.bucket.json}"
}

data "aws_iam_policy_document" "user_s3" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.bucket.arn}/*",
    ]
  }
  statement {
    actions = [
      "s3:ListBucket"
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.bucket.arn}",
    ]
  }
}

resource "aws_iam_user_policy" "user_s3" {
    name = "s3"
    user = "${aws_iam_user.user.name}"
    policy = "${data.aws_iam_policy_document.user_s3.json}"
}

#
# ec2
#

resource "aws_key_pair" "ci" {
  key_name = "${aws_iam_user.user.name}-ci"
  public_key = "${var.ssh_public_key}"
}

data "aws_iam_policy_document" "user_ec2" {
  statement {
    actions = [
      "ec2:AssociateAddress",
      "ec2:AttachVolume",
      "ec2:CreateVolume",
      "ec2:DeleteSnapshot",
      "ec2:DeleteVolume",
      "ec2:DescribeAddresses",
      "ec2:DescribeImages",
      "ec2:DescribeInstances",
      "ec2:DescribeRegions",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSnapshots",
      "ec2:DescribeSubnets",
      "ec2:DescribeVolumes",
      "ec2:DetachVolume",
      "ec2:CreateSnapshot",
      "ec2:CreateTags",
      "ec2:RunInstances",
      "ec2:TerminateInstances",
      "ec2:RegisterImage",
      "ec2:DeregisterImage"
    ]
    effect = "Allow"
    resources = [
      "*"
    ]
  }
}

resource "aws_iam_user_policy" "user_ec2" {
    name = "ec2"
    user = "${aws_iam_user.user.name}"
    policy = "${data.aws_iam_policy_document.user_ec2.json}"
}

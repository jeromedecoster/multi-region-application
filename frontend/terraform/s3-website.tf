resource "aws_s3_bucket" "website" {
  provider = aws.primary
  bucket   = "${var.project_name}-website"

  force_destroy = true
}

data "aws_iam_policy_document" "policy" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.website.arn}/*"]
  }
}

resource "aws_s3_bucket_policy" "bucket_policy" {
  bucket = aws_s3_bucket.website.id
  policy = data.aws_iam_policy_document.policy.json
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "bucket_primary" {
  provider = aws.primary
  bucket   = "${var.project_name}-primary"
  acl      = "private"

  # prevents `changes made outside since the last terraform apply`
  tags = {}

  # versioning is required to use replication
  versioning {
    enabled = true
  }

  logging {
    target_bucket = aws_s3_bucket.log_bucket_primary.id
    target_prefix = "log/"
  }

  # required for : TODO ...
  cors_rule {
    # prevents `changes made outside since the last terraform apply`
    expose_headers = []

    allowed_headers = [
      "*",
    ]
    allowed_methods = [
      "GET",
      "POST",
      "PUT",
    ]
    allowed_origins = [
      "*",
    ]
  }

  force_destroy = true

  # WARN : because of `aws_s3_bucket_replication_configuration` usage below, we need to add the following `lifecycle`.
  # To avoid conflicts always add the following `lifecycle` object to the `aws_s3_bucket` resource of the source bucket.
  # https://devcoops.com/how-to-ignore-changes-in-terraform/
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration#usage-notes
  lifecycle {
    ignore_changes = [
      replication_configuration,
    ]
  }

  depends_on = [
    aws_s3_bucket.log_bucket_primary
  ]
}

resource "aws_s3_bucket" "log_bucket_primary" {
  provider = aws.primary
  bucket   = "${var.project_name}-log-primary"

  # prevents `changes made outside since the last terraform apply`
  tags = {}

  # required : https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket#acl
  acl = "log-delivery-write"

  force_destroy = true
}

#
# replication
#

data "aws_iam_policy_document" "s3_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["s3.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "replication_to_secondary_bucket" {
  name               = "${var.project_name}-replication-to-bucket-role"
  assume_role_policy = data.aws_iam_policy_document.s3_assume_role.json
}

data "aws_iam_policy_document" "replication_to_secondary_bucket" {
  statement {
    actions = [
      "s3:GetReplicationConfiguration",
      "s3:GetObjectVersionForReplication",
      "s3:GetObjectVersionAcl",
      "s3:GetObjectVersionTagging",
      "s3:ListBucket"
    ]
    resources = [
      "${aws_s3_bucket.bucket_primary.arn}",
      "${aws_s3_bucket.bucket_primary.arn}/*"
    ]
  }

  statement {
    actions = [
      "s3:ReplicateObject",
      "s3:ReplicateDelete",
      "s3:ReplicateTags",
      "s3:GetObjectVersionTagging"
    ]
    resources = [
      "${aws_s3_bucket.bucket_secondary.arn}",
      "${aws_s3_bucket.bucket_secondary.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "replication_to_secondary_bucket" {
  name   = "${var.project_name}-replication-to-bucket-role-policy"
  policy = data.aws_iam_policy_document.replication_to_secondary_bucket.json
}


resource "aws_iam_role_policy_attachment" "replication_to_secondary_bucket" {
  role       = aws_iam_role.replication_to_secondary_bucket.name
  policy_arn = aws_iam_policy.replication_to_secondary_bucket.arn
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_replication_configuration
resource "aws_s3_bucket_replication_configuration" "replication_to_secondary_bucket" {
  # setting `provider` is required to prevent : error creating S3 replication configuration for bucket 
  # AuthorizationHeaderMalformed: The authorization header is malformed; the region 'X' is wrong; expecting 'Y'
  provider = aws.primary

  role   = aws_iam_role.replication_to_secondary_bucket.arn
  bucket = aws_s3_bucket.bucket_primary.id

  rule {
    id     = var.project_name
    prefix = "public"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.bucket_secondary.arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [
    aws_s3_bucket.bucket_primary,
    aws_s3_bucket.bucket_secondary
  ]
}
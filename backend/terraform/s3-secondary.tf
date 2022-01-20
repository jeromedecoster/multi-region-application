# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket
resource "aws_s3_bucket" "bucket_secondary" {
  provider = aws.secondary
  bucket   = "${var.project_name}-secondary"
  acl      = "private"

  # prevents `changes made outside since the last terraform apply`
  tags = {}

  # versioning is required to use replication
  versioning {
    enabled = true
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
}


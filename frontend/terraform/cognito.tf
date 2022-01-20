# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/s3_bucket
data "aws_s3_bucket" "bucket_primary" {
  provider = aws.primary
  bucket   = "${var.project_name}-primary"
}

data "aws_s3_bucket" "bucket_secondary" {
  provider = aws.secondary
  bucket   = "${var.project_name}-secondary"
}

data "aws_api_gateway_rest_api" "config_primary" {
  provider = aws.primary
  name     = "${var.project_name}-config-primary"
}

data "aws_api_gateway_rest_api" "config_secondary" {
  provider = aws.secondary
  name     = "${var.project_name}-config-secondary"
}

data "aws_api_gateway_rest_api" "store_primary" {
  provider = aws.primary
  name     = "${var.project_name}-store-primary"
}

data "aws_api_gateway_rest_api" "store_secondary" {
  provider = aws.secondary
  name     = "${var.project_name}-store-secondary"
}

resource "aws_cognito_user_pool" "pool" {
  name = var.project_name

  auto_verified_attributes = [
    "email",
  ]

  email_verification_subject = "[${var.project_name}] Demo UI Verification Code"
  email_verification_message = <<-EOT
        <p>
          Your verification code is <strong>{####}</strong>.
        </p>
    EOT

  admin_create_user_config {
    allow_admin_create_user_only = true

    invite_message_template {
      email_subject = "[${var.project_name}] Demo UI Login Information"
      email_message = <<-EOT
                <p>
                  Please sign in to the ${var.project_name} Demo UI using the temporary credentials below:<br />
                  ${aws_cloudfront_distribution.s3_distribution.domain_name}
                </p>
                <p>
                  Username: <strong>{username}</strong><br />
                  Temporary Password: <strong>{####}</strong>
                </p>
            EOT
      sms_message   = "Your username is {username} and temporary password is {####}."
    }
  }

  user_pool_add_ons {
    advanced_security_mode = "ENFORCED"
  }

  # verification_message_template {
  #     default_email_option = "CONFIRM_WITH_CODE"
  #     email_message        = <<-EOT
  #         <p>
  #           Your verification code is <strong>{####}</strong>.
  #         </p>
  #     EOT
  #     email_subject        = "[${var.project_name}] Demo UI Verification Code"
  # }

  depends_on = [
    aws_cloudfront_distribution.s3_distribution
  ]
}

resource "aws_cognito_user_pool_client" "client" {
  name         = "app_client"
  user_pool_id = aws_cognito_user_pool.pool.id
}

resource "aws_cognito_identity_pool" "identity_pool" {
  allow_unauthenticated_identities = false
  identity_pool_name               = var.project_name

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.client.id
    provider_name           = aws_cognito_user_pool.pool.endpoint
    server_side_token_check = false
  }
}

# Add aws_cognito_user resource
# https://github.com/hashicorp/terraform-provider-aws/issues/4542#issuecomment-712725794
resource "null_resource" "cognito_users" {
  provisioner "local-exec" {
    # https://awscli.amazonaws.com/v2/documentation/api/latest/reference/cognito-idp/admin-create-user.html
    command = <<COMMAND
aws cognito-idp admin-create-user \
  --user-pool-id ${aws_cognito_user_pool.pool.id} \
  --username ${var.cognito_username} \
  --user-attributes Name=email,Value=${var.cognito_email} \
  --region ${var.primary_region}
COMMAND
  }

  depends_on = [
    aws_cognito_user_pool.pool
  ]
}

data "aws_iam_policy_document" "cognito_identity_assume_role" {
  statement {
    # IMPORTANT : it is not `sts:AssumeRole` as usual but `sts:AssumeRoleWithWebIdentity`
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      # IMPORTANT : it is not `Service` as usual but `Federated`
      type        = "Federated"
      identifiers = ["cognito-identity.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "user_pool_inline_policy" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
    ]
    resources = [
      "${data.aws_s3_bucket.bucket_primary.arn}/public/*",
      "${data.aws_s3_bucket.bucket_secondary.arn}/public/*",
    ]
  }

  statement {
    actions = [
      "s3:ListBucket"
    ]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"

      values = [
        "public/",
        "public/*",
      ]
    }
    resources = [
      data.aws_s3_bucket.bucket_primary.arn,
      data.aws_s3_bucket.bucket_secondary.arn
    ]
  }

  statement {
    actions = [
      "execute-api:Invoke",
      "execute-api:ManageConnections",
    ]
    resources = [
      "${data.aws_api_gateway_rest_api.config_primary.execution_arn}/*",
      "${data.aws_api_gateway_rest_api.store_primary.execution_arn}/*",
      "${data.aws_api_gateway_rest_api.config_secondary.execution_arn}/*",
      "${data.aws_api_gateway_rest_api.store_secondary.execution_arn}/*"
    ]
  }
}

resource "aws_iam_role" "userpool_role" {

  name = "${var.project_name}-userpool-authenticated-role"

  assume_role_policy = data.aws_iam_policy_document.cognito_identity_assume_role.json

  inline_policy {
    name = "${var.project_name}-authenticated-role-policy"

    policy = data.aws_iam_policy_document.user_pool_inline_policy.json
  }

  depends_on = [
    data.aws_s3_bucket.bucket_primary,
    data.aws_s3_bucket.bucket_secondary,
    data.aws_api_gateway_rest_api.config_primary,
    data.aws_api_gateway_rest_api.store_primary,
    data.aws_api_gateway_rest_api.config_secondary,
    data.aws_api_gateway_rest_api.store_secondary
  ]
}

resource "aws_cognito_identity_pool_roles_attachment" "identity_attachment" {
  identity_pool_id = aws_cognito_identity_pool.identity_pool.id
  roles = {
    "authenticated" = aws_iam_role.userpool_role.arn
  }
}
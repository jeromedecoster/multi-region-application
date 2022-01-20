# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket#attributes-reference
output "bucket_website" {
  value = aws_s3_bucket.website.id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_identity_pool#attributes-reference
output "identity_pool_id" {
  value = aws_cognito_identity_pool.identity_pool.id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool_client#attributes-reference
output "user_pool_client_id" {
  value = aws_cognito_user_pool_client.client.id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cognito_user_pool#attributes-reference
output "user_pool_id" {
  value = aws_cognito_user_pool.pool.id
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution#attributes-reference
output "domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.domain_name
}
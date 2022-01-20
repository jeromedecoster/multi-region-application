output "bucket_primary" {
  value = aws_s3_bucket.bucket_primary.id
}

output "bucket_secondary" {
  value = aws_s3_bucket.bucket_secondary.id
}

output "apigateway_config_url_primary" {
  value = aws_api_gateway_stage.config_primary.invoke_url
}

output "apigateway_config_url_secondary" {
  value = aws_api_gateway_stage.config_secondary.invoke_url
}

output "apigateway_store_url_primary" {
  value = aws_api_gateway_stage.store_primary.invoke_url
}

output "apigateway_store_url_secondary" {
  value = aws_api_gateway_stage.store_secondary.invoke_url
}

output "dynamodb_config_name" {
  value = aws_dynamodb_table.config.name
}

output "dynamodb_config_primary_arn" {
  value = aws_dynamodb_table.config.arn
}

output "dynamodb_config_secondary_arn" {
  value = data.aws_dynamodb_table.config_secondary.arn
}

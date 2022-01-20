resource "aws_dynamodb_table" "config" {
  provider         = aws.primary
  name             = "${var.project_name}-config"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "appId"
  write_capacity   = 0
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "appId"
    type = "S"
  }

  point_in_time_recovery {
    enabled = false
  }

  server_side_encryption {
    enabled = true
  }

  # prevents `changes made outside since the last terraform apply`
  tags = {}

  # IMPORTANT : with `replica` in `aws_dynamodb_table` no need to use `dynamodb_global_table`
  # writing `replica` will :
  # - create another dynamodb table in the region defined by `region_name`
  # - and create the `Gobal table` replicas association between the 2 tables
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_global_table
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/dynamodb_table#global-tables
  replica {
    region_name = var.secondary_region
  }
}

resource "aws_dynamodb_table_item" "config_item" {
  provider   = aws.primary
  table_name = aws_dynamodb_table.config.name
  hash_key   = aws_dynamodb_table.config.hash_key

  item = <<ITEM
{
  "appId": {"S": "${var.app_state_uuid}"},
  "state": {"S": "active"}
}
ITEM

  depends_on = [
    aws_dynamodb_table.config
  ]
}

# get reference to the dynamodb replica dynamically created above by `replica { ... }`
data "aws_dynamodb_table" "config_secondary" {
  provider = aws.secondary
  name     = aws_dynamodb_table.config.name
}

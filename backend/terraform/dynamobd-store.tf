resource "aws_dynamodb_table" "store" {
  provider         = aws.primary
  name             = "${var.project_name}-store"
  billing_mode     = "PAY_PER_REQUEST"
  hash_key         = "commentId"
  read_capacity    = 0
  write_capacity   = 0
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"

  attribute {
    name = "commentId"
    type = "S"
  }

  attribute {
    name = "photoId"
    type = "S"
  }

  global_secondary_index {
    hash_key           = "photoId"
    name               = "photoId"
    non_key_attributes = []
    projection_type    = "ALL"
    read_capacity      = 0
    write_capacity     = 0
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


resource "aws_dynamodb_table_item" "store_item" {
  provider   = aws.primary
  table_name = aws_dynamodb_table.store.name
  hash_key   = aws_dynamodb_table.store.hash_key

  # technically commentId + photoId are differents
  # but this is just to test the api using shell scipts
  item = <<ITEM
{
  "commentId": {"S": "${var.app_state_uuid}"},
  "photoId": {"S": "${var.app_state_uuid}"},
  "user": {"S": "jerome"},
  "message": {"S": "my comment"}
}
ITEM

  depends_on = [
    aws_dynamodb_table.store
  ]
}

# get reference to the dynamodb replica dynamically created above by `replica { ... }`
data "aws_dynamodb_table" "store_secondary" {
  provider = aws.secondary
  name     = aws_dynamodb_table.store.name
}

resource "aws_api_gateway_rest_api" "store_secondary" {
  provider = aws.secondary
  name     = "${var.project_name}-store-secondary"

  description = var.project_name
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "comments_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.store_secondary.id
  parent_id   = aws_api_gateway_rest_api.store_secondary.root_resource_id
  path_part   = "comments"
}

resource "aws_api_gateway_resource" "photoid_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.store_secondary.id
  parent_id   = aws_api_gateway_resource.comments_secondary.id
  path_part   = "{photoId}"
}

#
# GET
#

resource "aws_api_gateway_method" "photos_get_secondary" {
  provider      = aws.secondary
  rest_api_id   = aws_api_gateway_rest_api.store_secondary.id
  resource_id   = aws_api_gateway_resource.photoid_secondary.id
  http_method   = "GET"
  authorization = "NONE"

  depends_on = [
    aws_api_gateway_resource.photoid_secondary
  ]
}

data "aws_iam_policy_document" "store_secondary_credentials_inline_policy" {
  statement {
    actions = ["dynamodb:Query"]
    resources = [
      "${data.aws_dynamodb_table.store_secondary.arn}/index/photoId"
    ]
  }

  statement {
    actions = ["dynamodb:PutItem"]
    resources = [
      data.aws_dynamodb_table.store_secondary.arn
    ]
  }
}

resource "aws_iam_role" "photos_credentials_role_secondary" {
  provider = aws.secondary
  name     = "${var.project_name}-comments-secondary-role"

  assume_role_policy = data.aws_iam_policy_document.apigateway_assume_role.json

  inline_policy {
    name   = "${var.project_name}-credentials-inline-policy"
    policy = data.aws_iam_policy_document.store_secondary_credentials_inline_policy.json
  }

  depends_on = [
    data.aws_dynamodb_table.store_secondary
  ]
  #   inline_policy {
  #     name = "${var.project_name}--comments-api-gateway-policy"
  #     policy = jsonencode(
  #       {
  #         Statement = [
  #           {
  #             Action = [
  #               "dynamodb:PutItem",
  #             ]
  #             Effect = "Allow"
  #             Resource = [
  #               aws_dynamodb_table.store.arn
  #             ]
  #           },
  #           {
  #             Action = [
  #               "dynamodb:Query",
  #             ]
  #             Effect = "Allow"
  #             Resource = [
  #               "${aws_dynamodb_table.store.arn}/index/photoId"
  #             ]
  #           },
  #         ]
  #       }
  #     )
  #   }
}

resource "aws_api_gateway_integration" "photos_get_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.store_secondary.id
  resource_id = aws_api_gateway_resource.photoid_secondary.id
  http_method = "GET"
  type        = "AWS"
  credentials = aws_iam_role.photos_credentials_role_secondary.arn
  uri         = "arn:aws:apigateway:${var.secondary_region}:dynamodb:action/Query"

  integration_http_method = "POST"
  passthrough_behavior    = "NEVER"

  request_templates = {
    "application/json" = jsonencode(
      {
        ExpressionAttributeValues = {
          ":v1" = {
            S = "$input.params('photoId')"
          }
        }
        IndexName              = "photoId"
        KeyConditionExpression = "photoId = :v1"
        TableName              = data.aws_dynamodb_table.store_secondary.name
      }
    )
  }

  depends_on = [
    data.aws_dynamodb_table.store_secondary,
    aws_api_gateway_method.photos_get_secondary
  ]
}

resource "aws_api_gateway_method_response" "photos_get_response_200_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.store_secondary.id
  resource_id = aws_api_gateway_resource.photoid_secondary.id
  http_method = "GET"
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false
    "method.response.header.Access-Control-Allow-Methods" = false
    "method.response.header.Access-Control-Allow-Origin"  = false
  }

  depends_on = [
    aws_api_gateway_method.photos_get_secondary
  ]
}

resource "aws_api_gateway_integration_response" "photos_get_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.store_secondary.id
  resource_id = aws_api_gateway_resource.photoid_secondary.id
  http_method = "GET"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = <<-EOT
            #set($inputRoot = $input.path('$')) {
              "comments": [
                #foreach($elem in $inputRoot.Items) {
                  "commentId": "$elem.commentId.S",
                  "user": "$elem.user.S",
                  "message": "$elem.message.S"
                }#if($foreach.hasNext),#end
              #end
              ]
            }
        EOT
  }

  depends_on = [
    aws_api_gateway_integration.photos_get_secondary,
    aws_api_gateway_method_response.photos_get_response_200_secondary
  ]
}

#
# OPTIONS
#

resource "aws_api_gateway_method" "photos_options_secondary" {
  provider      = aws.secondary
  rest_api_id   = aws_api_gateway_rest_api.store_secondary.id
  resource_id   = aws_api_gateway_resource.photoid_secondary.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "photos_options_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.store_secondary.id
  resource_id = aws_api_gateway_resource.photoid_secondary.id
  http_method = "OPTIONS"
  type        = "MOCK"

  # https://github.com/squidfunk/terraform-aws-api-gateway-enable-cors/blob/master/main.tf
  content_handling = "CONVERT_TO_TEXT"

  request_templates = {
    "application/json" = jsonencode(
      {
        statusCode = 200
      }
    )
  }

  depends_on = [
    data.aws_dynamodb_table.store_secondary,
    aws_api_gateway_method.photos_options_secondary
  ]
}

resource "aws_api_gateway_method_response" "photos_options_response_200_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.store_secondary.id
  resource_id = aws_api_gateway_resource.photoid_secondary.id
  http_method = "OPTIONS"
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
  response_parameters = {
    "method.response.header.Access-Control-Max-Age"       = true
    "method.response.header.Access-Control-Allow-Headers" = true # false
    "method.response.header.Access-Control-Allow-Methods" = true # false
    "method.response.header.Access-Control-Allow-Origin"  = true # false
  }

  depends_on = [
    aws_api_gateway_method.photos_options_secondary,
  ]
}

resource "aws_api_gateway_integration_response" "photos_options_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.store_secondary.id
  resource_id = aws_api_gateway_resource.photoid_secondary.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Max-Age"       = "'7200'"
    "method.response.header.Access-Control-Allow-Headers" = "'Authorization,Content-Type,X-Amz-Date,X-Amz-Security-Token,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,HEAD,GET,POST,PUT,PATCH,DELETE'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.photos_options_secondary,
    aws_api_gateway_method_response.photos_options_response_200_secondary,
  ]
}

#
# POST
#

resource "aws_api_gateway_method" "photos_post_secondary" {
  provider      = aws.secondary
  rest_api_id   = aws_api_gateway_rest_api.store_secondary.id
  resource_id   = aws_api_gateway_resource.photoid_secondary.id
  http_method   = "POST"
  authorization = "NONE"

  depends_on = [
    aws_api_gateway_resource.photoid_secondary
  ]
}

resource "aws_api_gateway_integration" "photos_post_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.store_secondary.id
  resource_id = aws_api_gateway_resource.photoid_secondary.id
  http_method = "POST"
  type        = "AWS"

  credentials = aws_iam_role.photos_credentials_role.arn

  uri = "arn:aws:apigateway:${var.secondary_region}:dynamodb:action/PutItem"

  integration_http_method = "POST"
  passthrough_behavior    = "NEVER"

  request_templates = {
    "application/json" = jsonencode(
      {
        Item = {
          commentId = {
            S = "$input.path('$.commentId')"
          }
          message = {
            S = "$input.path('$.message')"
          }
          photoId = {
            S = "$input.path('$.photoId')"
          }
          user = {
            S = "$input.path('$.user')"
          }
        }
        TableName = data.aws_dynamodb_table.store_secondary.name #aws_dynamodb_table.store.name
      }
    )
  }

  depends_on = [
    aws_dynamodb_table.store,
    aws_api_gateway_method.photos_post_secondary
  ]
}

resource "aws_api_gateway_method_response" "photos_post_response_200_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.store_secondary.id
  resource_id = aws_api_gateway_resource.photoid_secondary.id
  http_method = "POST"
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = false
    "method.response.header.Access-Control-Allow-Methods" = false
    "method.response.header.Access-Control-Allow-Origin"  = false
  }

  depends_on = [
    aws_api_gateway_method.photos_post_secondary
  ]
}

resource "aws_api_gateway_integration_response" "photos_post_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.store_secondary.id
  resource_id = aws_api_gateway_resource.photoid_secondary.id
  http_method = "POST"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,POST,OPTIONS'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.photos_post_secondary,
    aws_api_gateway_method_response.photos_post_response_200_secondary
  ]
}

#
# DEPLOYMENT
#

resource "aws_api_gateway_deployment" "store_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.store_secondary.id

  # VERY IMPORTANT : lot of wasting time if you don't use this trick because
  # aws_api_gateway_deployment doesn't get updated after changes
  # for example, a POST method created is not deployed and you receive {"message":"Missing Authentication Token"}
  # you can waste a lot of time exploring the API resources / IAM role etc ... and it's just a stage not deployed
  # https://registry.terraform.io/providers/hashicorp%20%20/aws/latest/docs/resources/api_gateway_stage
  # https://medium.com/coryodaniel/til-forcing-terraform-to-deploy-a-aws-api-gateway-deployment-ed36a9f60c1a
  # https://github.com/hashicorp/terraform-provider-aws/issues/162
  triggers = {
    redeployment = sha1(file("${path.module}/apigateway-store-secondary.tf"))
  }

  lifecycle {
    create_before_destroy = true
  }

  # wait API ready
  depends_on = [
    aws_api_gateway_integration_response.photos_get_secondary,
    aws_api_gateway_integration_response.photos_options_secondary,
    aws_api_gateway_integration_response.photos_post_secondary
  ]
}

resource "aws_api_gateway_stage" "store_secondary" {
  # IMPORTANT : a new stage deployed takes less or more than 20 or 30 seconds to take effect in 
  # the browser after being deployed on the AWS website. Some CORS errors may show up in between 
  # and then disappear
  provider      = aws.secondary
  rest_api_id   = aws_api_gateway_rest_api.store_secondary.id
  deployment_id = aws_api_gateway_deployment.store_secondary.id
  stage_name    = "prod"
}
resource "aws_api_gateway_rest_api" "store_primary" {
  provider = aws.primary
  name     = "${var.project_name}-store-primary"

  description = var.project_name
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "comments_primary" {
  provider    = aws.primary
  rest_api_id = aws_api_gateway_rest_api.store_primary.id
  parent_id   = aws_api_gateway_rest_api.store_primary.root_resource_id
  path_part   = "comments"
}

resource "aws_api_gateway_resource" "photoid_primary" {
  provider    = aws.primary
  rest_api_id = aws_api_gateway_rest_api.store_primary.id
  parent_id   = aws_api_gateway_resource.comments_primary.id
  path_part   = "{photoId}"
}

#
# GET
#

resource "aws_api_gateway_method" "photos_get_primary" {
  provider      = aws.primary
  rest_api_id   = aws_api_gateway_rest_api.store_primary.id
  resource_id   = aws_api_gateway_resource.photoid_primary.id
  http_method   = "GET"
  authorization = "NONE"

  depends_on = [
    aws_api_gateway_resource.photoid_primary
  ]
}

resource "aws_iam_role" "photos_credentials_role" {
  provider = aws.primary
  name     = "${var.project_name}-comments-role"

  assume_role_policy = jsonencode(
    {
      Statement = [
        {
          Action = "sts:AssumeRole"
          Effect = "Allow"
          Principal = {
            Service = "apigateway.amazonaws.com"
          }
        },
      ]
      Version = "2012-10-17"
    }
  )

  inline_policy {
    name = "${var.project_name}--comments-api-gateway-policy"
    policy = jsonencode(
      {
        Statement = [
          {
            Action = [
              "dynamodb:PutItem",
            ]
            Effect = "Allow"
            Resource = [
              aws_dynamodb_table.store.arn
            ]
          },
          {
            Action = [
              "dynamodb:Query",
            ]
            Effect = "Allow"
            Resource = [
              "${aws_dynamodb_table.store.arn}/index/photoId"
            ]
          },
        ]
      }
    )
  }
}

resource "aws_api_gateway_integration" "photos_get_primary" {
  provider    = aws.primary
  rest_api_id = aws_api_gateway_rest_api.store_primary.id
  resource_id = aws_api_gateway_resource.photoid_primary.id
  http_method = "GET"
  type        = "AWS"
  credentials = aws_iam_role.photos_credentials_role.arn
  uri         = "arn:aws:apigateway:${var.primary_region}:dynamodb:action/Query"

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
        TableName              = aws_dynamodb_table.store.name
      }
    )
  }

  depends_on = [
    aws_dynamodb_table.store,
    aws_api_gateway_method.photos_get_primary
  ]
}

resource "aws_api_gateway_method_response" "photos_get_response_200_primary" {
  provider    = aws.primary
  rest_api_id = aws_api_gateway_rest_api.store_primary.id
  resource_id = aws_api_gateway_resource.photoid_primary.id
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
    aws_api_gateway_method.photos_get_primary
  ]
}

resource "aws_api_gateway_integration_response" "photos_get_primary" {
  provider    = aws.primary
  rest_api_id = aws_api_gateway_rest_api.store_primary.id
  resource_id = aws_api_gateway_resource.photoid_primary.id
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
    aws_api_gateway_integration.photos_get_primary,
    aws_api_gateway_method_response.photos_get_response_200_primary
  ]
}

#
# OPTIONS
#

resource "aws_api_gateway_method" "photos_options_primary" {
  provider      = aws.primary
  rest_api_id   = aws_api_gateway_rest_api.store_primary.id
  resource_id   = aws_api_gateway_resource.photoid_primary.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "photos_options_primary" {
  provider    = aws.primary
  rest_api_id = aws_api_gateway_rest_api.store_primary.id
  resource_id = aws_api_gateway_resource.photoid_primary.id
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
    aws_dynamodb_table.store,
    aws_api_gateway_method.photos_options_primary
  ]
}

resource "aws_api_gateway_method_response" "photos_options_response_200_primary" {
  provider    = aws.primary
  rest_api_id = aws_api_gateway_rest_api.store_primary.id
  resource_id = aws_api_gateway_resource.photoid_primary.id
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
    aws_api_gateway_method.photos_options_primary,
  ]
}

resource "aws_api_gateway_integration_response" "photos_options_primary" {
  provider    = aws.primary
  rest_api_id = aws_api_gateway_rest_api.store_primary.id
  resource_id = aws_api_gateway_resource.photoid_primary.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Max-Age"       = "'7200'"
    "method.response.header.Access-Control-Allow-Headers" = "'Authorization,Content-Type,X-Amz-Date,X-Amz-Security-Token,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,HEAD,GET,POST,PUT,PATCH,DELETE'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.photos_options_primary,
    aws_api_gateway_method_response.photos_options_response_200_primary,
  ]
}

#
# POST
#

resource "aws_api_gateway_method" "photos_post_primary" {
  provider      = aws.primary
  rest_api_id   = aws_api_gateway_rest_api.store_primary.id
  resource_id   = aws_api_gateway_resource.photoid_primary.id
  http_method   = "POST"
  authorization = "NONE"

  depends_on = [
    aws_api_gateway_resource.photoid_primary
  ]
}

resource "aws_api_gateway_integration" "photos_post_primary" {
  provider    = aws.primary
  rest_api_id = aws_api_gateway_rest_api.store_primary.id
  resource_id = aws_api_gateway_resource.photoid_primary.id
  http_method = "POST"
  type        = "AWS"

  credentials = aws_iam_role.photos_credentials_role.arn

  uri = "arn:aws:apigateway:${var.primary_region}:dynamodb:action/PutItem"

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
        TableName = aws_dynamodb_table.store.name
      }
    )
  }

  depends_on = [
    aws_dynamodb_table.store,
    aws_api_gateway_method.photos_post_primary
  ]
}

resource "aws_api_gateway_method_response" "photos_post_response_200_primary" {
  provider    = aws.primary
  rest_api_id = aws_api_gateway_rest_api.store_primary.id
  resource_id = aws_api_gateway_resource.photoid_primary.id
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
    aws_api_gateway_method.photos_post_primary
  ]
}

resource "aws_api_gateway_integration_response" "photos_post_primary" {
  provider    = aws.primary
  rest_api_id = aws_api_gateway_rest_api.store_primary.id
  resource_id = aws_api_gateway_resource.photoid_primary.id
  http_method = "POST"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = "'Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token'"
    "method.response.header.Access-Control-Allow-Methods" = "'GET,OPTIONS,POST'"
    "method.response.header.Access-Control-Allow-Origin"  = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.photos_post_primary,
    aws_api_gateway_method_response.photos_post_response_200_primary
  ]
}

#
# DEPLOYMENT
#

resource "aws_api_gateway_deployment" "store_primary" {
  provider    = aws.primary
  rest_api_id = aws_api_gateway_rest_api.store_primary.id

  # VERY IMPORTANT : lot of wasting time if you don't use this trick because
  # aws_api_gateway_deployment doesn't get updated after changes
  # for example, a POST method created is not deployed and you receive {"message":"Missing Authentication Token"}
  # you can waste a lot of time exploring the API resources / IAM role etc ... and it's just a stage not deployed
  # https://registry.terraform.io/providers/hashicorp%20%20/aws/latest/docs/resources/api_gateway_stage
  # https://medium.com/coryodaniel/til-forcing-terraform-to-deploy-a-aws-api-gateway-deployment-ed36a9f60c1a
  # https://github.com/hashicorp/terraform-provider-aws/issues/162
  triggers = {
    redeployment = sha1(file("${path.module}/apigateway-store-primary.tf"))
  }

  lifecycle {
    create_before_destroy = true
  }

  # wait API ready
  depends_on = [
    aws_api_gateway_integration_response.photos_get_primary,
    aws_api_gateway_integration_response.photos_options_primary,
    aws_api_gateway_integration_response.photos_post_primary
  ]
}

resource "aws_api_gateway_stage" "store_primary" {
  provider = aws.primary
  # IMPORTANT : a new stage deployed takes less or more than 20 or 30 seconds to take effect in 
  # the browser after being deployed on the AWS website. Some CORS errors may show up in between 
  # and then disappear
  rest_api_id   = aws_api_gateway_rest_api.store_primary.id
  deployment_id = aws_api_gateway_deployment.store_primary.id
  stage_name    = "prod"
}
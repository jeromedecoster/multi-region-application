resource "aws_api_gateway_rest_api" "config_secondary" {
  provider = aws.secondary
  name     = "${var.project_name}-config-secondary"

  description = var.project_name
  
  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "state_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.config_secondary.id
  parent_id   = aws_api_gateway_rest_api.config_secondary.root_resource_id
  path_part   = "state"
}

resource "aws_api_gateway_resource" "appid_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.config_secondary.id
  parent_id   = aws_api_gateway_resource.state_secondary.id
  path_part   = "{appId}"
}

#
# GET
#

resource "aws_api_gateway_method" "get_secondary" {
  provider      = aws.secondary
  rest_api_id   = aws_api_gateway_rest_api.config_secondary.id
  resource_id   = aws_api_gateway_resource.appid_secondary.id
  http_method   = "GET"
  authorization = "NONE"

  depends_on = [
    aws_api_gateway_resource.appid_secondary
  ]
}

# data "aws_iam_policy_document" "apigateway_assume_role" {
#   statement {
#     actions = ["sts:AssumeRole"]
#     principals {
#       type        = "Service"
#       identifiers = ["apigateway.amazonaws.com"]
#     }
#   }
# }

data "aws_iam_policy_document" "config_secondary_credentials_inline_policy" {
  statement {
    actions = ["dynamodb:Query"]
    resources = [
      data.aws_dynamodb_table.config_secondary.arn
    ]
  }
}

resource "aws_iam_role" "config_secondary_credentials_role" {
  provider = aws.secondary
  name     = "${var.project_name}-app-config-credentials-secondary-role"

  assume_role_policy = data.aws_iam_policy_document.apigateway_assume_role.json

  inline_policy {
    name   = "${var.project_name}-credentials-inline-policy"
    policy = data.aws_iam_policy_document.config_secondary_credentials_inline_policy.json
  }

  depends_on = [
    data.aws_dynamodb_table.config_secondary
  ]
}

resource "aws_api_gateway_integration" "get_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.config_secondary.id
  resource_id = aws_api_gateway_resource.appid_secondary.id
  http_method = "GET"
  type        = "AWS"
  credentials = aws_iam_role.config_secondary_credentials_role.arn
  uri         = "arn:aws:apigateway:${var.secondary_region}:dynamodb:action/Query"

  integration_http_method = "POST"
  passthrough_behavior    = "NEVER"

  request_templates = {
    "application/json" = jsonencode(
      {
        ExpressionAttributeValues = {
          ":v1" = {
            S = "$input.params('appId')"
          }
        }
        KeyConditionExpression = "appId = :v1"
        TableName              = data.aws_dynamodb_table.config_secondary.name
      }
    )
  }

  depends_on = [
    data.aws_dynamodb_table.config_secondary,
    aws_api_gateway_method.get_secondary
  ]
}

resource "aws_api_gateway_method_response" "get_secondary_response_200" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.config_secondary.id
  resource_id = aws_api_gateway_resource.appid_secondary.id
  http_method = "GET"
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = aws_api_gateway_method_response.get_response_200_primary.response_parameters

  depends_on = [
    aws_api_gateway_method.get_secondary
  ]
}

resource "aws_api_gateway_integration_response" "get_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.config_secondary.id
  resource_id = aws_api_gateway_resource.appid_secondary.id
  http_method = "GET"
  status_code = "200"

  response_parameters = aws_api_gateway_integration_response.get_primary.response_parameters

  response_templates = {
    "application/json" = aws_api_gateway_integration_response.get_primary.response_templates["application/json"]
  }

  depends_on = [
    aws_api_gateway_integration.get_secondary,
    aws_api_gateway_method_response.get_secondary_response_200
  ]
}

#
# OPTIONS
#

resource "aws_api_gateway_method" "options_secondary" {
  provider      = aws.secondary
  rest_api_id   = aws_api_gateway_rest_api.config_secondary.id
  resource_id   = aws_api_gateway_resource.appid_secondary.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.config_secondary.id
  resource_id = aws_api_gateway_resource.appid_secondary.id
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
    aws_api_gateway_method.options_secondary
  ]
}

resource "aws_api_gateway_method_response" "options_response_200_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.config_secondary.id
  resource_id = aws_api_gateway_resource.appid_secondary.id
  http_method = "OPTIONS"
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Max-Age"       = true
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [
    aws_api_gateway_method.options_secondary,
  ]
}

resource "aws_api_gateway_integration_response" "options_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.config_secondary.id
  resource_id = aws_api_gateway_resource.appid_secondary.id
  http_method = "OPTIONS"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Max-Age"       = "'7200'"
    "method.response.header.Access-Control-Allow-Headers" = "'Authorization,Content-Type,X-Amz-Date,X-Amz-Security-Token,X-Api-Key'"
    # "'Content-Type,X-Amz-Date,Authorization,X-Api-Key,X-Amz-Security-Token'"
    # "'Authorization,Content-Type,X-Amz-Date,X-Amz-Security-Token,X-Api-Key'"
    "method.response.header.Access-Control-Allow-Methods" = "'OPTIONS,HEAD,GET,POST,PUT,PATCH,DELETE'"
    # "'GET,OPTIONS'"
    # "'OPTIONS,HEAD,GET,POST,PUT,PATCH,DELETE'"
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  depends_on = [
    aws_api_gateway_integration.options_secondary,
    aws_api_gateway_method_response.options_response_200_secondary,
  ]
}

#
# DEPLOYMENT
#

resource "aws_api_gateway_deployment" "config_secondary" {
  provider    = aws.secondary
  rest_api_id = aws_api_gateway_rest_api.config_secondary.id

  # VERY IMPORTANT : lot of wasting time if you don't use this trick because
  # aws_api_gateway_deployment doesn't get updated after changes
  # for example, a POST method created is not deployed and you receive {"message":"Missing Authentication Token"}
  # you can waste a lot of time exploring the API resources / IAM role etc ... and it's just a stage not deployed
  # https://registry.terraform.io/providers/hashicorp%20%20/aws/latest/docs/resources/api_gateway_stage
  # https://medium.com/coryodaniel/til-forcing-terraform-to-deploy-a-aws-api-gateway-deployment-ed36a9f60c1a
  # https://github.com/hashicorp/terraform-provider-aws/issues/162
  triggers = {
    redeployment = sha1(file("${path.module}/apigateway-config-secondary.tf"))
  }

  lifecycle {
    create_before_destroy = true
  }

  # wait API ready
  depends_on = [
    aws_api_gateway_integration_response.get_secondary,
    aws_api_gateway_integration_response.options_secondary
  ]
}

resource "aws_api_gateway_stage" "config_secondary" {
  # IMPORTANT : a new stage deployed takes less or more than 20 or 30 seconds to take effect in 
  # the browser after being deployed on the AWS website. Some CORS errors may show up in between 
  # and then disappear
  provider      = aws.secondary
  rest_api_id   = aws_api_gateway_rest_api.config_secondary.id
  deployment_id = aws_api_gateway_deployment.config_secondary.id
  stage_name    = "prod"
}

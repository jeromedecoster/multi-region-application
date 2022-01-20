resource "aws_api_gateway_rest_api" "config_primary" {
  provider = aws.primary
  name     = "${var.project_name}-config-primary"

  description = var.project_name

  endpoint_configuration {
    types = ["REGIONAL"]
  }
}

resource "aws_api_gateway_resource" "state_primary" {
  rest_api_id = aws_api_gateway_rest_api.config_primary.id
  parent_id   = aws_api_gateway_rest_api.config_primary.root_resource_id
  path_part   = "state"
}

resource "aws_api_gateway_resource" "appid_primary" {
  rest_api_id = aws_api_gateway_rest_api.config_primary.id
  parent_id   = aws_api_gateway_resource.state_primary.id
  path_part   = "{appId}"
}

#
# GET
#

resource "aws_api_gateway_method" "get_primary" {
  rest_api_id   = aws_api_gateway_rest_api.config_primary.id
  resource_id   = aws_api_gateway_resource.appid_primary.id
  http_method   = "GET"
  authorization = "NONE"

  depends_on = [
    aws_api_gateway_resource.appid_primary
  ]
}

data "aws_iam_policy_document" "apigateway_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["apigateway.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "config_credentials_inline_policy" {
  statement {
    actions = ["dynamodb:Query"]
    resources = [
      aws_dynamodb_table.config.arn
    ]
  }
}

resource "aws_iam_role" "config_credentials_role" {
  name = "${var.project_name}-app-config-credentials-role"

  assume_role_policy = data.aws_iam_policy_document.apigateway_assume_role.json

  inline_policy {
    name   = "${var.project_name}-credentials-inline-policy"
    policy = data.aws_iam_policy_document.config_credentials_inline_policy.json
  }

  depends_on = [
    aws_dynamodb_table.config
  ]
}

resource "aws_api_gateway_integration" "get_primary" {
  rest_api_id = aws_api_gateway_rest_api.config_primary.id
  resource_id = aws_api_gateway_resource.appid_primary.id
  http_method = "GET"
  type        = "AWS"
  credentials = aws_iam_role.config_credentials_role.arn
  uri         = "arn:aws:apigateway:${var.primary_region}:dynamodb:action/Query"

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
        TableName              = aws_dynamodb_table.config.name
      }
    )
  }

  depends_on = [
    aws_dynamodb_table.config,
    aws_api_gateway_method.get_primary
  ]
}

resource "aws_api_gateway_method_response" "get_response_200_primary" {
  rest_api_id = aws_api_gateway_rest_api.config_primary.id
  resource_id = aws_api_gateway_resource.appid_primary.id
  http_method = "GET"
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }

  response_parameters = {
    "method.response.header.Access-Control-Allow-Headers" = true
    "method.response.header.Access-Control-Allow-Methods" = true
    "method.response.header.Access-Control-Allow-Origin"  = true
  }

  depends_on = [
    aws_api_gateway_method.get_primary
  ]
}

resource "aws_api_gateway_integration_response" "get_primary" {
  rest_api_id = aws_api_gateway_rest_api.config_primary.id
  resource_id = aws_api_gateway_resource.appid_primary.id
  http_method = "GET"
  status_code = "200"

  response_parameters = {
    "method.response.header.Access-Control-Allow-Origin" = "'*'"
  }

  response_templates = {
    "application/json" = <<-EOT
            #set($inputRoot = $input.path('$'))
            #if($inputRoot.Items.size() == 1)
                #set($item = $inputRoot.Items.get(0))
                {
                  "state": "$item.state.S"
                }
            #{else}
                {}
                ## Return an empty object
            #end
        EOT
  }

  depends_on = [
    aws_api_gateway_integration.get_primary,
    aws_api_gateway_method_response.get_response_200_primary
  ]
}

#
# OPTIONS
#

resource "aws_api_gateway_method" "options_primary" {
  rest_api_id   = aws_api_gateway_rest_api.config_primary.id
  resource_id   = aws_api_gateway_resource.appid_primary.id
  http_method   = "OPTIONS"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "options_primary" {
  rest_api_id = aws_api_gateway_rest_api.config_primary.id
  resource_id = aws_api_gateway_resource.appid_primary.id
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
    aws_api_gateway_method.options_primary
  ]
}

resource "aws_api_gateway_method_response" "options_response_200_primary" {
  rest_api_id = aws_api_gateway_rest_api.config_primary.id
  resource_id = aws_api_gateway_resource.appid_primary.id
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
    aws_api_gateway_method.options_primary,
  ]
}

resource "aws_api_gateway_integration_response" "options_primary" {
  rest_api_id = aws_api_gateway_rest_api.config_primary.id
  resource_id = aws_api_gateway_resource.appid_primary.id
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
    aws_api_gateway_integration.options_primary,
    aws_api_gateway_method_response.options_response_200_primary,
  ]
}

#
# DEPLOYMENT
#

resource "aws_api_gateway_deployment" "config_primary" {
  rest_api_id = aws_api_gateway_rest_api.config_primary.id

  # VERY IMPORTANT : lot of wasting time if you don't use this trick because
  # aws_api_gateway_deployment doesn't get updated after changes
  # for example, a POST method created is not deployed and you receive {"message":"Missing Authentication Token"}
  # you can waste a lot of time exploring the API resources / IAM role etc ... and it's just a stage not deployed
  # https://registry.terraform.io/providers/hashicorp%20%20/aws/latest/docs/resources/api_gateway_stage
  # https://medium.com/coryodaniel/til-forcing-terraform-to-deploy-a-aws-api-gateway-deployment-ed36a9f60c1a
  # https://github.com/hashicorp/terraform-provider-aws/issues/162
  triggers = {
    redeployment = sha1(file("${path.module}/apigateway-config-primary.tf"))
  }

  lifecycle {
    create_before_destroy = true
  }

  # wait API ready
  depends_on = [
    aws_api_gateway_integration_response.get_primary,
    aws_api_gateway_integration_response.options_primary
  ]
}

resource "aws_api_gateway_stage" "config_primary" {
  # IMPORTANT : a new stage deployed takes less or more than 20 or 30 seconds to take effect in 
  # the browser after being deployed on the AWS website. Some CORS errors may show up in between 
  # and then disappear
  rest_api_id   = aws_api_gateway_rest_api.config_primary.id
  deployment_id = aws_api_gateway_deployment.config_primary.id
  stage_name    = "prod"
}
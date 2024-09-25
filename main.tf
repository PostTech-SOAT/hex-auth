resource "aws_cognito_user_pool" "user_pool" {
  name                = replace("${var.application}_user_pool", "-", "_")
  username_attributes = ["email"]

  schema {
    attribute_data_type = "String"
    mutable             = true
    name                = "email"
    required            = true
    string_attribute_constraints {
      min_length = 1
      max_length = 2048
    }
  }
  schema {
    attribute_data_type = "String"
    name                = "name"
    required            = true
    mutable             = true
  }

  schema {
    attribute_data_type      = "String"
    name                     = "cpf"
    developer_only_attribute = false
    required                 = false
    mutable                  = true
  }

  schema {
    attribute_data_type      = "Boolean"
    name                     = "isadmin"
    developer_only_attribute = false
    required                 = false
    mutable                  = true
  }

  password_policy {
    minimum_length    = 6
    require_lowercase = false
    require_numbers   = false
    require_symbols   = false
    require_uppercase = false
  }

  lifecycle {
    ignore_changes = [
      schema,
      username_attributes
    ]
  }
}


data "aws_iam_role" "lambda_exec_role" {
  name = "LabRole"
}

resource "aws_lambda_function" "post_cognito" {
  filename         = "${path.module}/lambda/post_function/main.zip"
  function_name    = "PostCognitoLambda"
  role             = data.aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/post_function/main.zip")
  runtime          = "nodejs16.x"
  timeout          = 30
  environment {
    variables = {
      USER_POOL_ID = aws_cognito_user_pool.user_pool.id
    }
  }
}

resource "aws_lambda_function" "get_cognito" {
  filename         = "${path.module}/lambda/get_function/main.zip"
  function_name    = "GetCognitoLambda"
  role             = data.aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/get_function/main.zip")
  runtime          = "nodejs16.x"
  timeout          = 30
  environment {
    variables = {
      USER_POOL_ID = aws_cognito_user_pool.user_pool.id
    }
  }
}

resource "aws_api_gateway_rest_api" "cognito_api" {
  name = "${var.application}-public-api"
}

resource "aws_api_gateway_resource" "client_resource" {
  rest_api_id = aws_api_gateway_rest_api.cognito_api.id
  parent_id   = aws_api_gateway_rest_api.cognito_api.root_resource_id
  path_part   = "client"
}

resource "aws_api_gateway_method" "post_method" {
  rest_api_id   = aws_api_gateway_rest_api.cognito_api.id
  resource_id   = aws_api_gateway_resource.client_resource.id
  http_method   = "POST"
  authorization = "NONE"
}


resource "aws_api_gateway_method" "get_method" {
  rest_api_id   = aws_api_gateway_rest_api.cognito_api.id
  resource_id   = aws_api_gateway_resource.client_resource.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration_response" "get_integration_response_200" {
  rest_api_id = aws_api_gateway_rest_api.cognito_api.id
  resource_id = aws_api_gateway_resource.client_resource.id
  http_method = aws_api_gateway_method.get_method.http_method
  status_code = "200"

  response_templates = {
    "application/json" = "$input.body"
  }
}

resource "aws_api_gateway_method_response" "get_method_response_200" {
  rest_api_id = aws_api_gateway_rest_api.cognito_api.id
  resource_id = aws_api_gateway_resource.client_resource.id
  http_method = aws_api_gateway_method.get_method.http_method
  status_code = "200"

  response_models = {
    "application/json" = "Empty"
  }
}

resource "aws_api_gateway_integration" "post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.cognito_api.id
  resource_id             = aws_api_gateway_resource.client_resource.id
  http_method             = aws_api_gateway_method.post_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.post_cognito.invoke_arn
}

resource "aws_api_gateway_integration" "get_integration" {
  rest_api_id             = aws_api_gateway_rest_api.cognito_api.id
  resource_id             = aws_api_gateway_resource.client_resource.id
  http_method             = aws_api_gateway_method.get_method.http_method
  type                    = "AWS"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.get_cognito.invoke_arn
  request_templates = {
    "application/json" = <<EOF
    {
      "cpf": "$input.params('cpf')"
    }
    EOF
  }
  passthrough_behavior = "WHEN_NO_TEMPLATES"
  content_handling     = "CONVERT_TO_TEXT"
}

resource "aws_lambda_permission" "post_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_cognito.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.cognito_api.execution_arn}/*/POST/client"
}

resource "aws_lambda_permission" "get_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.get_cognito.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.cognito_api.execution_arn}/*/GET/client"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.cognito_api.id
  stage_name  = "prod"

  depends_on = [
    aws_api_gateway_method.post_method,
    aws_api_gateway_method.get_method
  ]
}

output "api_endpoint" {
  value = "${aws_api_gateway_deployment.api_deployment.invoke_url}/client"
}

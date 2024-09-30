resource "aws_cognito_user_pool" "user_pool" {
  name                = replace("${var.application}_user_pool", "-", "_")

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
    attribute_data_type      = "Boolean"
    name                     = "isadmin"
    developer_only_attribute = true
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

resource "aws_lambda_function" "get_cliente_cognito" {
  filename         = "${path.module}/lambda/get_function/cliente.zip"
  function_name    = "GetClienteCognitoLambda"
  role             = data.aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/get_function/cliente.zip")
  runtime          = "nodejs16.x"
  timeout          = 30
  environment {
    variables = {
      USER_POOL_ID = aws_cognito_user_pool.user_pool.id
    }
  }
}

resource "aws_lambda_function" "get_admin_cognito" {
  filename         = "${path.module}/lambda/get_function/admin.zip"
  function_name    = "GetAdminCognitoLambda"
  role             = data.aws_iam_role.lambda_exec_role.arn
  handler          = "index.handler"
  source_code_hash = filebase64sha256("${path.module}/lambda/get_function/admin.zip")
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

resource "aws_api_gateway_integration" "post_integration" {
  rest_api_id             = aws_api_gateway_rest_api.cognito_api.id
  resource_id             = aws_api_gateway_resource.client_resource.id
  http_method             = aws_api_gateway_method.post_method.http_method
  type                    = "AWS_PROXY"
  integration_http_method = "POST"
  uri                     = aws_lambda_function.post_cognito.invoke_arn
}

resource "aws_lambda_permission" "post_api_gateway" {
  statement_id  = "AllowExecutionFromAPIGateway"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.post_cognito.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.cognito_api.execution_arn}/*/POST/client"
}

resource "aws_api_gateway_deployment" "api_deployment" {
  rest_api_id = aws_api_gateway_rest_api.cognito_api.id
  stage_name  = "prod"

  depends_on = [
    aws_api_gateway_method.post_method
  ]
}

output "api_endpoint" {
  value = "${aws_api_gateway_deployment.api_deployment.invoke_url}/client"
}

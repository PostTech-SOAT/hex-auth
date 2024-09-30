resource "aws_lambda_function" "this" {
  for_each         = { for idx, value in var.lambda_config : idx => value }
  filename         = "${path.module}/${each.value.directory_name}/${each.value.zip_file_name}"
  function_name    = each.value.function_name
  role             = var.lambda_execution_role_arn
  handler          = each.value.handler
  source_code_hash = filebase64sha256("${path.module}/${each.value.directory_name}/${each.value.zip_file_name}")
  runtime          = each.value.runtime
  timeout          = each.value.timeout
  environment {
    variables = {
      USER_POOL_ID = "${var.cognito_user_pool_id}"
    }
  }
}

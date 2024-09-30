module "cognito" {
  source = "./modules/cognito"

  application = var.application
  cognito_schema_definition = var.cognito_schema_definition
  cognito_password_policy   = var.cognito_password_policy
}

module "lambda" {
  source = "./modules/lambda"

  application               = var.application
  lambda_config             = var.lambda_config
  cognito_user_pool_id      = module.cognito.cognito_data.id
  lambda_execution_role_arn = data.aws_iam_role.lambda_exec_role.arn
}
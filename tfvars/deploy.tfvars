##############################################################################
#                      GENERAL                                               #
##############################################################################
application = "hexburger"
aws_region  = "us-east-1"

##############################################################################
#                      COGNITO                                               #
##############################################################################
cognito_schema_definition = [
  {
    attribute_data_type = "String"
    name                = "email"
    required            = true
    mutable             = true
  },
  {
    attribute_data_type = "String"
    name                = "name"
    required            = true
    mutable             = true
  },
  {
    attribute_data_type = "Boolean"
    name                = "isadmin"
    required            = false
    mutable             = true
  }
]

cognito_password_policy = {
  minimum_length    = 6
  require_lowercase = false
  require_numbers   = false
  require_symbols   = false
  require_uppercase = false
}

##############################################################################
#                      LAMBDA                                                #
##############################################################################
lambda_config = [
  {
    function_name  = "CriarClienteCognito"
    directory_name = "post_function"
    zip_file_name  = "main.zip"
    handler        = "index.handler"
    runtime        = "nodejs16.x"
    timeout        = 30
    is_authorizer  = false
  },
  {
    function_name  = "BuscarClienteCognito"
    directory_name = "get_function"
    zip_file_name  = "cliente.zip"
    handler        = "index.handler"
    runtime        = "nodejs16.x"
    timeout        = 30
    is_authorizer  = false
  },
  {
    function_name  = "BuscarAdminCognito"
    directory_name = "get_function"
    zip_file_name  = "admin.zip"
    handler        = "index.handler"
    runtime        = "nodejs16.x"
    timeout        = 30
    is_authorizer  = true
  }
]

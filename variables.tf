variable "application" {
  type = string
}
variable "aws_region" {
  type = string
}
variable "cognito_schema_definition" {
  type = list(object({
    attribute_data_type = string
    name                = string
    required            = bool
    mutable             = bool
  }))
  
}
variable "cognito_password_policy" {
  type = object({
    minimum_length    = number
    require_lowercase = bool
    require_numbers   = bool
    require_symbols   = bool
    require_uppercase = bool
  })

}
variable "lambda_config" {
  type = list(object({
    function_name  = string
    directory_name = string
    zip_file_name  = string
    handler        = string
    runtime        = string
    timeout        = number
  }))
}
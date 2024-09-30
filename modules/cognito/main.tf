resource "aws_cognito_user_pool" "user_pool" {
  name                = replace("${var.application}_user_pool", "-", "_")

  dynamic "schema" {
    for_each = { for idx, value in var.cognito_schema_definition : idx => value }
    content {
      attribute_data_type = schema.value.attribute_data_type
      name                = schema.value.name
      required            = schema.value.required
      mutable             = schema.value.mutable
    }
  }

  password_policy {
    minimum_length    = var.cognito_password_policy.minimum_length
    require_lowercase = var.cognito_password_policy.require_lowercase
    require_numbers   = var.cognito_password_policy.require_numbers
    require_symbols   = var.cognito_password_policy.require_symbols
    require_uppercase = var.cognito_password_policy.require_uppercase
  }

  lifecycle {
    ignore_changes = [
      schema,
      username_attributes
    ]
  }
}
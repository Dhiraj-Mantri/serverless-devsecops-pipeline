output "api_url" {
  description = "Public URL of the API"
  value       = module.api_gateway.api_url
}

output "table_name" {
  value = module.dynamodb.table_name
}

output "lambda_name" {
  value = module.lambda.function_name
}

locals {
  name = "${var.project}-${var.environment}"

  tags = {
    Project     = var.project
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}

module "dynamodb" {
  source     = "../modules/dynamodb"
  table_name = local.name
  tags       = local.tags
}

module "lambda" {
  source        = "../modules/lambda"
  function_name = local.name
  source_dir    = "${path.root}/../../src"
  table_name    = module.dynamodb.table_name
  table_arn     = module.dynamodb.table_arn
  tags          = local.tags
}

module "api_gateway" {
  source               = "../modules/api_gateway"
  api_name             = local.name
  lambda_invoke_arn    = module.lambda.invoke_arn
  lambda_function_name = module.lambda.function_name
  tags                 = local.tags
}

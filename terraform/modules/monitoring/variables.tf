variable "name" {
  type = string
}

variable "lambda_function_name" {
  type = string
}

variable "api_id" {
  type = string
}

variable "alert_email" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

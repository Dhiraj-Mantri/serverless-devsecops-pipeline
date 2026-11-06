variable "function_name" {
  type = string
}

variable "source_dir" {
  type = string
}

variable "table_name" {
  type = string
}

variable "table_arn" {
  type = string
}

variable "runtime" {
  type    = string
  default = "python3.12"
}

variable "log_retention_days" {
  type    = number
  default = 14
}

variable "tags" {
  type    = map(string)
  default = {}
}

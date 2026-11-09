variable "project" {
  type    = string
  default = "items-api"
}

variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be dev or prod."
  }
}

variable "alert_email" {
  type        = string
  description = "Email address for CloudWatch alarm notifications"
}

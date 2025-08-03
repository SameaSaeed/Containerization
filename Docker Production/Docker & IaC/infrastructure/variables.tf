variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "docker-iac-terraform"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "development"
}

variable "web_replicas" {
  description = "Number of web application replicas"
  type        = number
  default     = 2
}
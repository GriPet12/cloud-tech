variable "admin_password" {
  description = "Пароль для адміна (localadmin). Має бути складним."
  type        = string
  sensitive   = true
}

variable "location" {
  description = "Регіон Azure для розгортання ресурсів."
  type        = string
  default     = "East US"
}
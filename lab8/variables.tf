variable "location" {
  description = "Регіон Azure для розгортання."
  default     = "West US 3"
}

variable "resource_group_name" {
  description = "Назва групи ресурсів."
  default     = "az104-rg8"
}

variable "admin_username" {
  description = "Ім'я користувача-адміністратора для VM."
  default     = "localadmin"
}

variable "admin_password" {
  description = "Пароль адміністратора для VM. Має відповідати вимогам складності Azure."
  type        = string
  sensitive   = true
}
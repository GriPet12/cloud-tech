variable "admin_email" {
  description = "Your email address for alert notifications."
  type        = string
  sensitive   = true
}

variable "admin_password" {
  description = "A complex password for the virtual machine."
  type        = string
  sensitive   = true
}

variable "local_timezone" {
  description = "Your local timezone ID (e.g., 'FLE Standard Time' for Ukraine). Find yours here: https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/default-time-zones"
  type        = string
  default     = "FLE Standard Time"
}

variable "location" {
  description = "The Azure region to deploy resources."
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
  default     = "az104-rg11"
}
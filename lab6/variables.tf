variable "location" {
  description = "Azure region for all resources."
  type        = string
}

variable "resource_group" {
  description = "Name of the resource group."
  type        = string
}

variable "admin_username" {
  description = "Admin username for the VMs."
  type        = string
  default     = "azureuser"
}

variable "admin_password" {
  description = "Admin password for the VMs."
  type        = string
  sensitive   = true
}
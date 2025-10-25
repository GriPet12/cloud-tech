variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
  default     = "az104-rg7"
}

variable "location" {
  description = "The Azure region where resources will be deployed."
  type        = string
  default     = "East US"
}

variable "storage_account_prefix" {
  description = "A prefix for the globally unique storage account name."
  type        = string
  default     = "az104labsa"
}
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg" {
  name     = "az104-rg3"
  location = "East US"
}

# аналог Task 1
resource "azurerm_managed_disk" "disk1" {
  name                 = "az104-disk1-tf"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
    storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32 
}

# аналог Task 2
resource "azurerm_managed_disk" "disk2" {
  name                 = "az104-disk2-tf"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = 64
}
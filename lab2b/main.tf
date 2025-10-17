terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}
provider "random" {}

#task 1
resource "azurerm_resource_group" "rg" {
  name     = "az104-rg2"
  location = "East US"

  tags = {
    "Cost Center" = "000"
  }
}

#task 2 and 3
data "azurerm_policy_definition" "inherit_tag" {
  display_name = "Inherit a tag from the resource group if missing"
}

resource "azurerm_resource_group_policy_assignment" "apply_tagging" {
  name                 = "inherit-cost-center-tag"
  resource_group_id    = azurerm_resource_group.rg.id
  policy_definition_id = data.azurerm_policy_definition.inherit_tag.id
  location             = azurerm_resource_group.rg.location
  enforce              = true
  description          = "Inherit the Cost Center tag from the resource group if missing."
  
  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    "tagName" : {
      "value" : "Cost Center"
    }
  })
}

resource "random_string" "sa_name" {
  length  = 20
  special = false
  upper   = false
}

resource "azurerm_storage_account" "testsa" {
  name                     = random_string.sa_name.result
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

#task 4
resource "azurerm_management_lock" "rg_lock" {
  name       = "rg-lock"
  scope      = azurerm_resource_group.rg.id
  lock_level = "CanNotDelete"
  notes      = "Lock to prevent accidental deletion of the resource group."
}
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~>2.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

#task 1
resource "azurerm_management_group" "mg" {
  display_name = "az104-mg1"
  name         = "az104-mg1"
}

#task 2
data "azuread_group" "helpdesk_group" {
  display_name = "helpdesk"
}

resource "azurerm_role_assignment" "vm_contributor_assignment" {
  scope                = azurerm_management_group.mg.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = data.azuread_group.helpdesk_group.object_id
}

#task 3
data "azurerm_role_definition" "support_request_contributor" {
  name = "Support Request Contributor"
}

resource "azurerm_role_definition" "custom_support_role" {
  name        = "Custom Support Request"
  scope       = azurerm_management_group.mg.id
  description = "A custom contributor role for support requests."

  permissions {
    actions = data.azurerm_role_definition.support_request_contributor.permissions[0].actions

    not_actions = [
      "Microsoft.Support/register/action"
    ]
  }

  assignable_scopes = [
    azurerm_management_group.mg.id
  ]
}

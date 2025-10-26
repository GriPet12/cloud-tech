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

data "azurerm_subscription" "current" {}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "az104-vnet11"
  address_space       = ["10.11.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "snet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.11.0.0/24"]
}

resource "azurerm_public_ip" "pip" {
  name                = "az104-vm0-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_network_interface" "nic" {
  name                = "az104-vm0-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.snet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "az104-vm0"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "localadmin"
  admin_password      = var.admin_password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.nic.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }
}

resource "azurerm_log_analytics_workspace" "main" {
  name                = "az104-la-workspace"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_action_group" "main" {
  name                = "Alert-the-operations-team"
  resource_group_name = azurerm_resource_group.rg.name
  short_name          = "AlertOps"

  email_receiver {
    name          = "VM was deleted"
    email_address = var.admin_email
  }
}

resource "azurerm_monitor_activity_log_alert" "main" {
  name                = "VM was deleted"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [data.azurerm_subscription.current.id]
  description         = "A VM in your resource group was deleted"

  criteria {
    operation_name = "Microsoft.Compute/virtualMachines/delete"
    category       = "Administrative"

  }

  action {
    action_group_id = azurerm_monitor_action_group.main.id
  }
}

resource "azurerm_monitor_alert_processing_rule_suppression" "main" {
  name                = "Planned-Maintenance"
  resource_group_name = azurerm_resource_group.rg.name
  scopes              = [azurerm_resource_group.rg.id]
  description         = "Suppress notifications during planned maintenance."

  schedule {
    effective_from = formatdate("YYYY-MM-DD'T'22:00:00", timestamp())
    effective_until = formatdate("YYYY-MM-DD'T'07:00:00", timeadd(timestamp(), "24h"))
    time_zone      = var.local_timezone
  }
}
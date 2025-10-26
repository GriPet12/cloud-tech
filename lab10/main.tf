terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.1"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_password" "admin_password" {
  length           = 16
  special          = true
  override_special = "!@#$%&"
}

output "vm_admin_password" {
  value     = random_password.admin_password.result
  sensitive = true
}

resource "azurerm_resource_group" "rg1" {
  name     = "az104-rg-region1"
  location = "East US"
}

resource "azurerm_virtual_network" "vnet1" {
  name                = "az104-vnet-region1"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
}

resource "azurerm_subnet" "subnet1" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg1.name
  virtual_network_name = azurerm_virtual_network.vnet1.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "nic1" {
  name                = "az104-10-vm0-nic"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet1.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                = "az-104-10-vm0"
  resource_group_name = azurerm_resource_group.rg1.name
  location            = azurerm_resource_group.rg1.location
  size                = "Standard_B1s"
  admin_username      = "localadmin"
  admin_password      = random_password.admin_password.result
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.nic1.id,
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

resource "azurerm_recovery_services_vault" "rsv1" {
  name                = "az104-rsv-region1"
  location            = azurerm_resource_group.rg1.location
  resource_group_name = azurerm_resource_group.rg1.name
  sku                 = "Standard"

  storage_mode_type     = "GeoRedundant"
  soft_delete_enabled   = true
}

resource "azurerm_backup_policy_vm" "policy" {
  name                = "az104-backup"
  resource_group_name = azurerm_resource_group.rg1.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv1.name

  timezone = "UTC"

  backup {
    frequency = "Daily"
    time      = "00:00"
  }

  retention_daily {
    count = 30
  }

  instant_restore_retention_days = 2
}

resource "azurerm_backup_protected_vm" "vm_backup" {
  resource_group_name = azurerm_resource_group.rg1.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv1.name
  source_vm_id        = azurerm_linux_virtual_machine.vm.id
  backup_policy_id    = azurerm_backup_policy_vm.policy.id
}

resource "random_string" "sa_suffix" {
  length  = 8
  special = false
  upper   = false
}

resource "azurerm_storage_account" "diag_storage" {
  name                     = "stdiag${random_string.sa_suffix.result}"
  resource_group_name      = azurerm_resource_group.rg1.name
  location                 = azurerm_resource_group.rg1.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_monitor_diagnostic_setting" "rsv_diag" {
  name               = "Logs-and-Metrics-to-storage"
  target_resource_id = azurerm_recovery_services_vault.rsv1.id
  storage_account_id = azurerm_storage_account.diag_storage.id

  enabled_log {
    category = "AzureBackupReport"
  }

  enabled_log {
    category = "AddonAzureBackupJobs" 
  }

  enabled_log {
    category = "AddonAzureBackupAlerts"
  }

  enabled_log {
    category = "AzureSiteRecoveryJobs"
  }

  enabled_log {
    category = "AzureSiteRecoveryEvents"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}

resource "azurerm_resource_group" "rg2" {
  name     = "az104-rg-region2"
  location = "West US"
}

resource "azurerm_recovery_services_vault" "rsv2" {
  name                = "az104-rsv-region2"
  location            = azurerm_resource_group.rg2.location
  resource_group_name = azurerm_resource_group.rg2.name
  sku                 = "Standard"
}
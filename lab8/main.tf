resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "time_sleep" "wait_for_rg" {
  create_duration = "30s"

  depends_on = [
    azurerm_resource_group.rg
  ]
}

resource "azurerm_virtual_network" "vm_vnet" {
  name                = "vm-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  depends_on = [
    time_sleep.wait_for_rg
  ]
}

resource "azurerm_subnet" "vm_subnet" {
  name                 = "vm-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vm_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_network_interface" "vm_nic_1" {
  name                = "az104-vm1-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    time_sleep.wait_for_rg
  ]
}

resource "azurerm_network_interface" "vm_nic_2" {
  name                = "az104-vm2-nic"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnet.id
    private_ip_address_allocation = "Dynamic"
  }

  depends_on = [
    time_sleep.wait_for_rg
  ]
}

resource "azurerm_windows_virtual_machine" "vm1" {
  name                = "az104-vm1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.vm_nic_1.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  patch_mode = "AutomaticByPlatform"
  boot_diagnostics {
    storage_account_uri = null
  }

  depends_on = [
    time_sleep.wait_for_rg
  ]
}

resource "azurerm_windows_virtual_machine" "vm2" {
  name                = "az104-vm2"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  network_interface_ids = [
    azurerm_network_interface.vm_nic_2.id,
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  patch_mode = "AutomaticByPlatform"
  boot_diagnostics {
    storage_account_uri = null
  }

  depends_on = [
    time_sleep.wait_for_rg
  ]
}

resource "azurerm_managed_disk" "vm1_disk" {
  name                 = "vm1-disk1"
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "StandardSSD_LRS"
  create_option        = "Empty"
  disk_size_gb         = 32

  depends_on = [
    time_sleep.wait_for_rg
  ]
}

resource "azurerm_virtual_machine_data_disk_attachment" "vm1_disk_attach" {
  managed_disk_id    = azurerm_managed_disk.vm1_disk.id
  virtual_machine_id = azurerm_windows_virtual_machine.vm1.id
  lun                = "10"
  caching            = "ReadWrite"
}

resource "azurerm_virtual_network" "vmss_vnet" {
  name                = "vmss-vnet"
  address_space       = ["10.82.0.0/20"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  depends_on = [
    time_sleep.wait_for_rg
  ]
}

resource "azurerm_subnet" "vmss_subnet" {
  name                 = "subnet0"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vmss_vnet.name
  address_prefixes     = ["10.82.0.0/24"]
}

resource "azurerm_network_security_group" "vmss_nsg" {
  name                = "vmss1-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {
    name                       = "allow-http"
    priority                   = 1010
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  depends_on = [
    time_sleep.wait_for_rg
  ]
}

resource "azurerm_public_ip" "vmss_lb_pip" {
  name                = "vmss-lb-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"

  depends_on = [
    time_sleep.wait_for_rg
  ]
}

resource "azurerm_lb" "vmss_lb" {
  name                = "vmss-lb"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.vmss_lb_pip.id
  }

  depends_on = [
    time_sleep.wait_for_rg
  ]
}

resource "azurerm_lb_backend_address_pool" "vmss_lb_pool" {
  loadbalancer_id = azurerm_lb.vmss_lb.id
  name            = "vmss-backend-pool"
}

resource "azurerm_lb_probe" "http_probe" {
  loadbalancer_id = azurerm_lb.vmss_lb.id
  name            = "http-probe"
  port            = 80
  protocol        = "Http"
  request_path    = "/"
}

resource "azurerm_lb_rule" "http_rule" {
  loadbalancer_id                = azurerm_lb.vmss_lb.id
  name                           = "http-rule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.vmss_lb_pool.id]
  probe_id                       = azurerm_lb_probe.http_probe.id
}

resource "azurerm_windows_virtual_machine_scale_set" "vmss" {
  name                = "vmss1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard_B1s"
  instances           = 2
  admin_username      = var.admin_username
  admin_password      = var.admin_password

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  network_interface {
    name    = "vmss-nic"
    primary = true
    network_security_group_id = azurerm_network_security_group.vmss_nsg.id

    ip_configuration {
      name      = "internal"
      primary   = true
      subnet_id = azurerm_subnet.vmss_subnet.id
      load_balancer_backend_address_pool_ids = [azurerm_lb_backend_address_pool.vmss_lb_pool.id]
    }
  }

  provision_vm_agent = true
  boot_diagnostics {
    storage_account_uri = null
  }

  depends_on = [
    time_sleep.wait_for_rg
  ]
}

resource "azurerm_monitor_autoscale_setting" "vmss_autoscale" {
  name                = "vmss1-autoscale-settings"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  target_resource_id  = azurerm_windows_virtual_machine_scale_set.vmss.id

  profile {
    name = "defaultProfile"

    capacity {
      default = 2
      minimum = 2
      maximum = 10
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "GreaterThan"
        threshold          = 70
      }
      scale_action {
        direction = "Increase"
        type      = "PercentChangeCount"
        value     = "50"
        cooldown  = "PT5M"
      }
    }

    rule {
      metric_trigger {
        metric_name        = "Percentage CPU"
        metric_resource_id = azurerm_windows_virtual_machine_scale_set.vmss.id
        time_grain         = "PT1M"
        statistic          = "Average"
        time_window        = "PT10M"
        time_aggregation   = "Average"
        operator           = "LessThan"
        threshold          = 30
      }
      scale_action {
        direction = "Decrease"
        type      = "PercentChangeCount"
        value     = "50"
        cooldown  = "PT5M"
      }
    }
  }

  depends_on = [
    time_sleep.wait_for_rg
  ]
}
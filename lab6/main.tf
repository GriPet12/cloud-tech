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

# task 1
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "az104-06-vnet1"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  address_space       = ["10.60.0.0/16"]
}

resource "azurerm_subnet" "vm_subnets" {
  count                = 3
  name                 = "subnet${count.index}"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.60.${count.index}.0/24"]
}

resource "azurerm_network_security_group" "vm_nsg" {
  name                = "vm-nsg"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  security_rule {
    name                       = "Allow_HTTP"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "Allow_SSH"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "Internet"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_interface" "vm_nic" {
  count               = 3
  name                = "az104-06-nic${count.index}"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.vm_subnets[count.index].id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_security_group_association" "nsg_assoc" {
  count                     = 3
  network_interface_id      = azurerm_network_interface.vm_nic[count.index].id
  network_security_group_id = azurerm_network_security_group.vm_nsg.id
}

resource "azurerm_linux_virtual_machine" "vm" {
  count                 = 3
  name                  = "az104-06-vm${count.index}"
  resource_group_name   = azurerm_resource_group.rg.name
  location              = azurerm_resource_group.rg.location
  size                  = "Standard_B1s"
  admin_username        = var.admin_username
  admin_password        = var.admin_password
  disable_password_authentication = false
  network_interface_ids = [azurerm_network_interface.vm_nic[count.index].id]
  custom_data           = filebase64("init.sh")

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

# task 2
resource "azurerm_public_ip" "lb_pip" {
  name                = "az104-lbpip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "lb" {
  name                = "az104-lb"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "az104-fe"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "lb_be" {
  name            = "az104-be"
  loadbalancer_id = azurerm_lb.lb.id
}

resource "azurerm_network_interface_backend_address_pool_association" "lb_be_assoc" {
  count                   = 2
  network_interface_id    = azurerm_network_interface.vm_nic[count.index].id
  ip_configuration_name   = "internal"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_be.id
}

resource "azurerm_lb_probe" "lb_hp" {
  name            = "az104-hp"
  loadbalancer_id = azurerm_lb.lb.id
  protocol        = "Tcp"
  port            = 80
  interval_in_seconds = 5
}

resource "azurerm_lb_rule" "lb_rule" {
  name                     = "az104-lbrule"
  loadbalancer_id          = azurerm_lb.lb.id
  protocol                 = "Tcp"
  frontend_port            = 80
  backend_port             = 80
  frontend_ip_configuration_name = "az104-fe"
  backend_address_pool_ids = [azurerm_lb_backend_address_pool.lb_be.id]
  probe_id                 = azurerm_lb_probe.lb_hp.id
  enable_floating_ip       = false
  enable_tcp_reset         = false
}

# task 3
resource "azurerm_subnet" "appgw_subnet" {
  name                 = "subnet-appgw"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.60.3.224/27"]
}

resource "azurerm_public_ip" "appgw_pip" {
  name                = "az104-gwpip"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1"]
}

resource "azurerm_application_gateway" "appgw" {
  name                = "az104-appgw"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location

  sku {
    name     = "Standard_v2"
    tier     = "Standard_v2"
    capacity = 2
  }

  ssl_policy {
    policy_name = "AppGwSslPolicy20220101"
    policy_type = "Predefined"
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw_subnet.id
  }

  frontend_port {
    name = "http-port"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appgw-fe-ip"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name = "az104-appgwbe"
    ip_addresses = [
      azurerm_network_interface.vm_nic[1].private_ip_address,
      azurerm_network_interface.vm_nic[2].private_ip_address
    ]
  }

  backend_address_pool {
    name = "az104-imagebe"
    ip_addresses = [azurerm_network_interface.vm_nic[1].private_ip_address]
  }

  backend_address_pool {
    name = "az104-videobe"
    ip_addresses = [azurerm_network_interface.vm_nic[2].private_ip_address]
  }

  backend_http_settings {
    name                  = "az104-http"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
  }

  http_listener {
    name                           = "az104-listener"
    frontend_ip_configuration_name = "appgw-fe-ip"
    frontend_port_name             = "http-port"
    protocol                       = "Http"
  }

  url_path_map {
    name = "path-map"
    default_backend_address_pool_name = "az104-appgwbe"
    default_backend_http_settings_name = "az104-http"

    path_rule {
      name = "images-rule"
      paths = ["/image/*"]
      backend_address_pool_name = "az104-imagebe"
      backend_http_settings_name = "az104-http"
    }

    path_rule {
      name = "videos-rule"
      paths = ["/video/*"]
      backend_address_pool_name = "az104-videobe"
      backend_http_settings_name = "az104-http"
    }
  }

  request_routing_rule {
    name = "az104-gwrule"
    rule_type = "PathBasedRouting"
    http_listener_name = "az104-listener"
    url_path_map_name = "path-map"
    priority = 10
  }

  depends_on = [
    azurerm_linux_virtual_machine.vm
  ]
}
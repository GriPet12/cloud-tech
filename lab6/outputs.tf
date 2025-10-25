output "load_balancer_public_ip" {
  description = "Public IP address of the Load Balancer (Task 2 Test)"
  value       = azurerm_public_ip.lb_pip.ip_address
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway (Task 3 Test)"
  value       = azurerm_public_ip.appgw_pip.ip_address
}
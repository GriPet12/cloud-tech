output "vmss_load_balancer_public_ip" {
  description = "Публічна IP-адреса балансувальника навантаження VMSS."
  value       = azurerm_public_ip.vmss_lb_pip.ip_address
}

output "vm1_private_ip" {
  description = "Приватна IP-адреса az104-vm1."
  value       = azurerm_network_interface.vm_nic_1.private_ip_address
}

output "vm2_private_ip" {
  description = "Приватна IP-адреса az104-vm2."
  value       = azurerm_network_interface.vm_nic_2.private_ip_address
}
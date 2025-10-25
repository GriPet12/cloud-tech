output "core_vm_private_ip" {
  description = "Приватна IP-адреса віртуальної машини CoreServicesVM (для Завдання 5)."
  value       = azurerm_windows_virtual_machine.core_vm.private_ip_address
}
output "app_service_name" {
  value = azurerm_linux_web_app.main.name
}

output "resource_group" {
  value = azurerm_resource_group.main.name
}
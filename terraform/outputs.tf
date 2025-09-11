output "app_service_name" {
  value = azurerm_linux_web_app.main.name
}

output "app_deploy_slot_name" {
  value = azurerm_linux_web_app_slot.stage.name
}

output "app_php_version" {
  value = azurerm_linux_web_app.main.site_config[0].application_stack[0].php_version
}

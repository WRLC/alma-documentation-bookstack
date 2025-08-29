output "resource_group_name" {
  description = "Name of the created resource group"
  value       = azurerm_resource_group.bookstack.name
}

output "resource_group_id" {
  description = "ID of the created resource group"
  value       = azurerm_resource_group.bookstack.id
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.bookstack.name
}

output "app_service_url" {
  description = "Default URL of the App Service"
  value       = "https://${azurerm_linux_web_app.bookstack.default_hostname}"
}

output "app_service_hostname" {
  description = "Default hostname of the App Service"
  value       = azurerm_linux_web_app.bookstack.default_hostname
}


output "mysql_server_name" {
  description = "Name of the existing MySQL Flexible Server"
  value       = data.azurerm_mysql_flexible_server.existing.name
}

output "mysql_server_fqdn" {
  description = "FQDN of the existing MySQL Flexible Server"
  value       = data.azurerm_mysql_flexible_server.existing.fqdn
  sensitive   = true
}

output "mysql_database_name" {
  description = "Name of the BookStack database"
  value       = azurerm_mysql_flexible_database.bookstack.name
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.bookstack.name
}

output "storage_account_primary_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = azurerm_storage_account.bookstack.primary_blob_endpoint
}

output "storage_container_name" {
  description = "Name of the uploads storage container"
  value       = azurerm_storage_container.uploads.name
}

output "application_insights_name" {
  description = "Name of the created Application Insights"
  value       = azurerm_application_insights.bookstack.name
}

output "application_insights_instrumentation_key" {
  description = "Application Insights instrumentation key"
  value       = azurerm_application_insights.bookstack.instrumentation_key
  sensitive   = true
}

output "application_insights_connection_string" {
  description = "Application Insights connection string"
  value       = azurerm_application_insights.bookstack.connection_string
  sensitive   = true
}

output "app_service_identity_principal_id" {
  description = "Principal ID of the App Service managed identity"
  value       = azurerm_linux_web_app.bookstack.identity[0].principal_id
}

output "stage_slot_url" {
  description = "URL of the staging deployment slot"
  value       = "https://${azurerm_linux_web_app.bookstack.default_hostname}/slots/stage"
}

output "stage_slot_hostname" {
  description = "Hostname of the staging deployment slot"
  value       = "${azurerm_linux_web_app.bookstack.name}-stage.azurewebsites.net"
}

output "deployment_instructions" {
  description = "Instructions for completing the deployment"
  value = <<-EOT
    Deployment completed! Next steps:

    1. Access your BookStack instance at: https://${azurerm_linux_web_app.bookstack.default_hostname}

    2. Set up deployment from your repository:
       - Configure GitHub Actions or Azure DevOps to deploy to: ${azurerm_linux_web_app.bookstack.name}
       - Use the publish profile from the Azure portal for authentication

    3. Run initial setup:
       - SSH into the App Service or use the Console
       - Run: php artisan migrate --force
       - Run: php artisan bookstack:create-admin (to create your first admin user)

    4. Configure any additional settings through the BookStack admin interface

    Database: ${data.azurerm_mysql_flexible_server.existing.fqdn}
    Storage: ${azurerm_storage_account.bookstack.primary_blob_endpoint}${azurerm_storage_container.uploads.name}/
  EOT
}

# Connection strings for debugging
output "database_connection_string" {
  description = "Database connection information"
  value = {
    host     = data.azurerm_mysql_flexible_server.existing.fqdn
    database = azurerm_mysql_flexible_database.bookstack.name
    username = mysql_user.bookstack.user
    port     = 3306
  }
  sensitive = true
}

output "bookstack_db_password" {
  description = "Generated password for BookStack database user"
  value       = random_password.bookstack_db_password.result
  sensitive   = true
}

output "storage_connection_info" {
  description = "Storage account connection information"
  value = {
    account_name   = azurerm_storage_account.bookstack.name
    container_name = azurerm_storage_container.uploads.name
    endpoint       = azurerm_storage_account.bookstack.primary_blob_endpoint
  }
}

# Staging Resources Outputs
output "stage_database_name" {
  description = "Name of the staging database"
  value       = azurerm_mysql_flexible_database.bookstack_stage.name
}

output "stage_database_user" {
  description = "Staging database username"
  value       = mysql_user.bookstack_stage.user
  sensitive   = true
}

output "stage_database_password" {
  description = "Generated password for staging database user"
  value       = random_password.bookstack_stage_db_password.result
  sensitive   = true
}

output "stage_storage_account_name" {
  description = "Name of the staging storage account"
  value       = azurerm_storage_account.bookstack_stage.name
}

output "stage_storage_endpoint" {
  description = "Primary blob endpoint of the staging storage account"
  value       = azurerm_storage_account.bookstack_stage.primary_blob_endpoint
}

output "stage_connection_info" {
  description = "Staging environment connection information"
  value = {
    url            = "https://${azurerm_linux_web_app.bookstack.name}-stage.azurewebsites.net"
    database       = azurerm_mysql_flexible_database.bookstack_stage.name
    storage        = azurerm_storage_account.bookstack_stage.name
    slot_name      = "stage"
  }
}

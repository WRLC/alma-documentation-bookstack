locals {
  service_name = "alma-documentation-bookstack"
  short_name   = "almadoc"
}

# App Service Plan
data "azurerm_service_plan" "existing" {
  name                = var.azure_service_plan_name
  resource_group_name = var.azure_service_plan_rg_name
}

# MySQL Flexible Server
data "azurerm_mysql_flexible_server" "existing" {
  name                = var.azure_mysql_flexible_server_name
  resource_group_name = var.azure_mysql_flexible_server_rg_name
}

# Log Analytics Workspace
data "azurerm_log_analytics_workspace" "existing" {
  name                = var.azure_log_analytics_workspace_name
  resource_group_name = var.azure_log_analytics_workspace_rg_name
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name     = "${local.service_name}-rg"
  location = data.azurerm_service_plan.existing.location
}

# Random identifier for storage account
resource "random_string" "unique" {
  length  = 8
  special = false
  upper = false
}

# Storage Account - production
resource "azurerm_storage_account" "prod" {
  name                     = "${local.short_name}${random_string.unique.result}sa"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Fileshare - production
resource "azurerm_storage_share" "prod" {
  name               = "${local.short_name}-storage"
  storage_account_id = azurerm_storage_account.prod.id
  quota              = 100
}

# Storage Account - staging
resource "azurerm_storage_account" "stage" {
  name                     = "${local.short_name}${random_string.unique.result}stagesa"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Fileshare - staging
resource "azurerm_storage_share" "stage" {
  name               = "${local.short_name}-storage"
  storage_account_id = azurerm_storage_account.stage.id
  quota              = 100
}

# MySQL Database - production
resource "azurerm_mysql_flexible_database" "prod" {
  name                = "${local.short_name}_prod"
  resource_group_name = data.azurerm_mysql_flexible_server.existing.resource_group_name
  server_name         = data.azurerm_mysql_flexible_server.existing.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# MySQL Database - staging
resource "azurerm_mysql_flexible_database" "stage" {
  name                = "${local.short_name}_stage"
  resource_group_name = data.azurerm_mysql_flexible_server.existing.resource_group_name
  server_name         = data.azurerm_mysql_flexible_server.existing.name
  charset             = "utf8mb4"
  collation           = "utf8mb4_unicode_ci"
}

# Random password - production
resource "random_password" "prod" {
  length  = 24
  special = false
}

# Random password - staging
resource "random_password" "stage" {
  length  = 24
  special = false
}

# MySQL User - production
resource "mysql_user" "prod" {
  user               = "${local.short_name}_prod_rw"
  plaintext_password = random_password.prod.result
  host               = "%"
}

# MySQL User - staging
resource "mysql_user" "stage" {
  user               = "${local.short_name}_stage_rw"
  plaintext_password = random_password.stage.result
  host               = "%"
}

# MySQL Grant - production
resource "mysql_grant" "prod" {
  user       = mysql_user.prod.user
  host       = mysql_user.prod.host
  database   = azurerm_mysql_flexible_database.prod.name
  privileges = ["ALL PRIVILEGES"]
}

# MySQL Grant - staging
resource "mysql_grant" "stage" {
  user       = mysql_user.stage.user
  host       = mysql_user.stage.host
  database   = azurerm_mysql_flexible_database.stage.name
  privileges = ["ALL PRIVILEGES"]
}

# Application Insights
resource "azurerm_application_insights" "main" {
  name                = "${local.service_name}-insights"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
}

# App Service
resource "azurerm_linux_web_app" "main" {
  name                = local.service_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = data.azurerm_service_plan.existing.id

  storage_account {
    access_key   = azurerm_storage_account.prod.primary_access_key
    account_name = azurerm_storage_account.prod.name
    name         = "bookstack_storage"
    share_name   = azurerm_storage_share.prod.name
    type         = "AzureFiles"
    mount_path   = "/home/site/wwwroot/BookStack/storage"
  }

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = true
    application_stack {
      php_version = "8.4"
    }
  }

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "APP_KEY"                               = var.bookstack_app_key
    "APP_URL"                               = ""
    "DB_HOST"                               = data.azurerm_mysql_flexible_server.existing.fqdn
    "DB_DATABASE"                           = azurerm_mysql_flexible_database.prod.name
    "DB_USERNAME"                           = mysql_user.prod.user
    "DB_PASSWORD"                           = random_password.prod.result
    "MAIL_DRIVER"                           = "smtp"
    "MAIL_FROM_NAME"                        = var.mail_from_name
    "MAIL_FROM"                             = var.mail_from
    "MAIL_HOST"                             = "smtp.azurecomm.net"
    "MAIL_PORT"                             = "587"
    "MAIL_USERNAME"                         = var.smtp_username
    "MAIL_PASSWORD"                         = var.smtp_password
    "MAIL_ENCRYPTION"                       = "tls"
    "FILE_UPLOAD_SIZE_LIMIT"                = 256
    "ALLOWED_IFRAME_SOURCES"                = var.allowed_iframe_source
  }

  sticky_settings {
    app_setting_names = [
      "APP_URL",
      "DB_HOST",
      "DB_DATABASE",
      "DB_USERNAME",
      "DB_PASSWORD"
    ]
  }
}

# Staging deployment slot
resource "azurerm_linux_web_app_slot" "stage" {
  name           = "stage"
  app_service_id = azurerm_linux_web_app.main.id

  storage_account {
    access_key   = azurerm_storage_account.stage.primary_access_key
    account_name = azurerm_storage_account.stage.name
    name         = "bookstack_storage"
    share_name   = azurerm_storage_share.stage.name
    type         = "AzureFiles"
    mount_path   = "/home/site/wwwroot/BookStack/storage"
  }

  identity {
    type = "SystemAssigned"
  }

  site_config {
    always_on = true
    application_stack {
      php_version = "8.4"
    }
  }

  app_settings = {
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = azurerm_application_insights.main.connection_string
    "APP_KEY"                               = var.bookstack_app_key
    "APP_URL"                               = ""
    "DB_HOST"                               = data.azurerm_mysql_flexible_server.existing.fqdn
    "DB_DATABASE"                           = azurerm_mysql_flexible_database.stage.name
    "DB_USERNAME"                           = mysql_user.stage.user
    "DB_PASSWORD"                           = random_password.stage.result
    "MAIL_DRIVER"                           = "smtp"
    "MAIL_FROM_NAME"                        = var.mail_from_name
    "MAIL_FROM"                             = var.mail_from
    "MAIL_HOST"                             = "smtp.azurecomm.net"
    "MAIL_PORT"                             = "587"
    "MAIL_USERNAME"                         = var.smtp_username
    "MAIL_PASSWORD"                         = var.smtp_password
    "MAIL_ENCRYPTION"                       = "tls"
    "FILE_UPLOAD_SIZE_LIMIT"                = 256
    "ALLOWED_IFRAME_SOURCES"                = var.allowed_iframe_source
  }
}
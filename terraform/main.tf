locals {
  service_name = "alma-documentation-bookstack"
  # Shortened names for resource limits
  short_name   = "almabookstack"  # For storage accounts (24 char limit)
  db_name      = "almabook"       # For MySQL usernames (32 char limit)
}

# Data sources for existing resources
data "azurerm_service_plan" "existing" {
  name                = var.existing_app_service_plan_name
  resource_group_name = var.existing_app_service_plan_rg
}

data "azurerm_log_analytics_workspace" "existing" {
  name                = var.existing_log_analytics_workspace_name
  resource_group_name = var.existing_log_analytics_workspace_rg
}

data "azurerm_mysql_flexible_server" "existing" {
  name                = var.existing_mysql_server_name
  resource_group_name = var.existing_mysql_server_rg
}

data "azurerm_communication_service" "existing" {
  name                = var.existing_acs_name
  resource_group_name = var.existing_acs_rg
}

# Resource Group
resource "azurerm_resource_group" "bookstack" {
  name     = "${local.service_name}-rg"
  location = data.azurerm_service_plan.existing.location
}

# Application Insights
resource "azurerm_application_insights" "bookstack" {
  name                = "${local.service_name}-insights"
  location            = azurerm_resource_group.bookstack.location
  resource_group_name = azurerm_resource_group.bookstack.name
  workspace_id        = data.azurerm_log_analytics_workspace.existing.id
  application_type    = "web"
}

# Generate random password for BookStack MySQL user
resource "random_password" "bookstack_db_password" {
  length  = 32
  special = false
}

# Generate random password for Staging MySQL user
resource "random_password" "bookstack_stage_db_password" {
  length  = 32
  special = false
}

# Generate random suffix for storage account name (must be globally unique)
resource "random_id" "storage_suffix" {
  byte_length = 4
}

# MySQL Database (create on existing server)
resource "azurerm_mysql_flexible_database" "bookstack" {
  name                = "${local.db_name}_prod"
  resource_group_name = var.existing_mysql_server_rg
  server_name         = data.azurerm_mysql_flexible_server.existing.name
  charset             = "utf8mb4"
  collation          = "utf8mb4_unicode_ci"
}

# Create MySQL user for BookStack
resource "mysql_user" "bookstack" {
  user               = "${local.db_name}_prod"
  host               = "%"
  plaintext_password = random_password.bookstack_db_password.result
}

# Grant privileges to BookStack user
resource "mysql_grant" "bookstack" {
  user       = mysql_user.bookstack.user
  host       = mysql_user.bookstack.host
  database   = azurerm_mysql_flexible_database.bookstack.name
  privileges = ["ALL PRIVILEGES"]

  depends_on = [mysql_user.bookstack, azurerm_mysql_flexible_database.bookstack]
}

# Staging Database
resource "azurerm_mysql_flexible_database" "bookstack_stage" {
  name                = "${local.db_name}_stage"
  resource_group_name = var.existing_mysql_server_rg
  server_name         = data.azurerm_mysql_flexible_server.existing.name
  charset             = "utf8mb4"
  collation          = "utf8mb4_unicode_ci"
}

# Create MySQL user for Staging
resource "mysql_user" "bookstack_stage" {
  user               = "${local.db_name}_stage"
  host               = "%"
  plaintext_password = random_password.bookstack_stage_db_password.result
}

# Grant privileges to Staging user
resource "mysql_grant" "bookstack_stage" {
  user       = mysql_user.bookstack_stage.user
  host       = mysql_user.bookstack_stage.host
  database   = azurerm_mysql_flexible_database.bookstack_stage.name
  privileges = ["ALL PRIVILEGES"]

  depends_on = [mysql_user.bookstack_stage, azurerm_mysql_flexible_database.bookstack_stage]
}

# Storage Account for file uploads
resource "azurerm_storage_account" "bookstack" {
  name                     = "${local.short_name}${random_id.storage_suffix.hex}"
  resource_group_name      = azurerm_resource_group.bookstack.name
  location                = azurerm_resource_group.bookstack.location
  account_tier            = "Standard"
  account_replication_type = "LRS"
  account_kind            = "StorageV2"

  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["DELETE", "GET", "HEAD", "MERGE", "POST", "OPTIONS", "PUT"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 200
    }
    
    versioning_enabled = true
    
    delete_retention_policy {
      days = 30
    }
    
    container_delete_retention_policy {
      days = 7
    }
  }
}

# Storage Container for uploads
resource "azurerm_storage_container" "uploads" {
  name                  = "uploads"
  storage_account_id    = azurerm_storage_account.bookstack.id
  container_access_type = "blob"
}

# Staging Storage Account for file uploads
resource "azurerm_storage_account" "bookstack_stage" {
  name                     = "${local.short_name}s${random_id.storage_suffix.hex}"
  resource_group_name      = azurerm_resource_group.bookstack.name
  location                = azurerm_resource_group.bookstack.location
  account_tier            = "Standard"
  account_replication_type = "LRS"
  account_kind            = "StorageV2"

  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["DELETE", "GET", "HEAD", "MERGE", "POST", "OPTIONS", "PUT"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 200
    }
  }
}

# Staging Storage Container for uploads
resource "azurerm_storage_container" "uploads_stage" {
  name                  = "uploads"
  storage_account_id    = azurerm_storage_account.bookstack_stage.id
  container_access_type = "blob"
}

# App Service
resource "azurerm_linux_web_app" "bookstack" {
  name                = local.service_name
  resource_group_name = azurerm_resource_group.bookstack.name
  location            = azurerm_resource_group.bookstack.location
  service_plan_id     = data.azurerm_service_plan.existing.id

  site_config {
    always_on                         = true
    ftps_state                       = "FtpsOnly"
    http2_enabled                    = true
    minimum_tls_version              = "1.2"
    use_32_bit_worker                = false
    vnet_route_all_enabled           = false
    scm_use_main_ip_restriction      = false
    health_check_path                = "/status"
    health_check_eviction_time_in_min = 2

    application_stack {
      php_version = "8.2"
    }

    cors {
      allowed_origins     = ["*"]
      support_credentials = false
    }
  }

  app_settings = {
    # Essential BookStack Configuration
    APP_KEY                     = var.app_key
    APP_URL                     = var.app_url

    # Database Configuration
    DB_HOST                     = data.azurerm_mysql_flexible_server.existing.fqdn
    DB_DATABASE                 = azurerm_mysql_flexible_database.bookstack.name
    DB_USERNAME                 = mysql_user.bookstack.user
    DB_PASSWORD                 = random_password.bookstack_db_password.result

    # Mail Configuration (Azure Communication Services)
    MAIL_DRIVER                 = "smtp"
    MAIL_FROM_NAME              = var.mail_from_name
    MAIL_FROM                   = var.mail_from
    MAIL_HOST                   = "${data.azurerm_communication_service.existing.name}.azurecomm.net"
    MAIL_PORT                   = "587"
    MAIL_USERNAME               = azuread_application.bookstack_smtp.client_id
    MAIL_PASSWORD               = azuread_application_password.bookstack_smtp.value
    MAIL_ENCRYPTION             = "tls"

    # File Upload Settings
    FILE_UPLOAD_SIZE_LIMIT      = var.file_upload_size_limit
    ALLOWED_IFRAME_SOURCES      = var.allowed_iframe_sources

    # Storage Configuration (Azure Blob Storage)
    STORAGE_TYPE                = "s3"
    STORAGE_S3_KEY              = azurerm_storage_account.bookstack.primary_access_key
    STORAGE_S3_SECRET           = azurerm_storage_account.bookstack.primary_access_key
    STORAGE_S3_BUCKET           = azurerm_storage_container.uploads.name
    STORAGE_S3_REGION           = azurerm_resource_group.bookstack.location
    STORAGE_S3_ENDPOINT         = "https://${azurerm_storage_account.bookstack.name}.blob.core.windows.net"
    STORAGE_URL                 = "https://${azurerm_storage_account.bookstack.name}.blob.core.windows.net/${azurerm_storage_container.uploads.name}"

    # Application Insights
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.bookstack.connection_string

    # Deployment Script
    POST_BUILD_SCRIPT_PATH      = "deploy.sh"

    # PHP Configuration
    PHP_INI_SCAN_DIR           = "/usr/local/etc/php/conf.d:/home/site"
    PHP_MEMORY_LIMIT           = "512M"
    PHP_UPLOAD_MAX_FILESIZE    = "${var.file_upload_size_limit}M"
    PHP_POST_MAX_SIZE          = "${var.file_upload_size_limit}M"
    PHP_MAX_EXECUTION_TIME     = "300"
    PHP_MAX_INPUT_TIME         = "300"
  }

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }

  identity {
    type = "SystemAssigned"
  }

  # Sticky settings (won't be swapped between slots)
  sticky_settings {
    app_setting_names = [
      "APP_KEY",
      "APP_URL",
      "DB_HOST", 
      "DB_DATABASE",
      "DB_USERNAME",
      "DB_PASSWORD",
      "STORAGE_TYPE",
      "STORAGE_S3_KEY",
      "STORAGE_S3_SECRET", 
      "STORAGE_S3_BUCKET",
      "STORAGE_S3_REGION",
      "STORAGE_S3_ENDPOINT",
      "STORAGE_URL"
    ]
  }
}

# App Registration for ACS SMTP Authentication
resource "azuread_application" "bookstack_smtp" {
  display_name = "${local.service_name}-smtp"
  owners       = [data.azuread_client_config.current.object_id]

  required_resource_access {
    resource_app_id = "1fd5118e-2576-4263-8130-9503064c837a" # Azure Communication Services

    resource_access {
      id   = "b3ac9d85-3307-4454-8680-e816b4c82e31" # Send.Email
      type = "Role"
    }
  }
}

# Service Principal for the App Registration
resource "azuread_service_principal" "bookstack_smtp" {
  client_id                    = azuread_application.bookstack_smtp.client_id
  app_role_assignment_required = false
  owners                       = [data.azuread_client_config.current.object_id]
}

# Client Secret for SMTP Authentication
resource "azuread_application_password" "bookstack_smtp" {
  application_id = azuread_application.bookstack_smtp.id
  display_name   = "SMTP Authentication"
  end_date       = "2025-12-31T23:59:59Z"
}

# Role Assignment - Grant ACS permissions to the service principal
resource "azurerm_role_assignment" "acs_contributor" {
  scope                = data.azurerm_communication_service.existing.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.bookstack_smtp.object_id
}

# Data source for current Azure AD config
data "azuread_client_config" "current" {}

# Deployment Slot - Stage
resource "azurerm_linux_web_app_slot" "stage" {
  name           = "stage"
  app_service_id = azurerm_linux_web_app.bookstack.id

  site_config {
    always_on                         = true
    ftps_state                       = "FtpsOnly"
    http2_enabled                    = true
    minimum_tls_version              = "1.2"
    use_32_bit_worker                = false
    vnet_route_all_enabled           = false
    scm_use_main_ip_restriction      = false
    health_check_path                = "/status"
    health_check_eviction_time_in_min = 2

    application_stack {
      php_version = "8.2"
    }

    cors {
      allowed_origins     = ["*"]
      support_credentials = false
    }
  }

  app_settings = {
    # Essential BookStack Configuration
    APP_KEY                     = var.app_key
    APP_URL                     = "https://${local.service_name}-stage.azurewebsites.net"

    # Database Configuration (Staging Database)
    DB_HOST                     = data.azurerm_mysql_flexible_server.existing.fqdn
    DB_DATABASE                 = azurerm_mysql_flexible_database.bookstack_stage.name
    DB_USERNAME                 = mysql_user.bookstack_stage.user
    DB_PASSWORD                 = random_password.bookstack_stage_db_password.result

    # Mail Configuration (Azure Communication Services)
    MAIL_DRIVER                 = "smtp"
    MAIL_FROM_NAME              = var.mail_from_name
    MAIL_FROM                   = var.mail_from
    MAIL_HOST                   = "${data.azurerm_communication_service.existing.name}.azurecomm.net"
    MAIL_PORT                   = "587"
    MAIL_USERNAME               = azuread_application.bookstack_smtp.client_id
    MAIL_PASSWORD               = azuread_application_password.bookstack_smtp.value
    MAIL_ENCRYPTION             = "tls"

    # File Upload Settings
    FILE_UPLOAD_SIZE_LIMIT      = var.file_upload_size_limit
    ALLOWED_IFRAME_SOURCES      = var.allowed_iframe_sources

    # Storage Configuration (Staging Storage)
    STORAGE_TYPE                = "s3"
    STORAGE_S3_KEY              = azurerm_storage_account.bookstack_stage.primary_access_key
    STORAGE_S3_SECRET           = azurerm_storage_account.bookstack_stage.primary_access_key
    STORAGE_S3_BUCKET           = azurerm_storage_container.uploads_stage.name
    STORAGE_S3_REGION           = azurerm_resource_group.bookstack.location
    STORAGE_S3_ENDPOINT         = "https://${azurerm_storage_account.bookstack_stage.name}.blob.core.windows.net"
    STORAGE_URL                 = "https://${azurerm_storage_account.bookstack_stage.name}.blob.core.windows.net/${azurerm_storage_container.uploads_stage.name}"

    # Application Insights
    APPLICATIONINSIGHTS_CONNECTION_STRING = azurerm_application_insights.bookstack.connection_string

    # Deployment Script
    POST_BUILD_SCRIPT_PATH      = "deploy.sh"

    # PHP Configuration
    PHP_INI_SCAN_DIR           = "/usr/local/etc/php/conf.d:/home/site"
    PHP_MEMORY_LIMIT           = "512M"
    PHP_UPLOAD_MAX_FILESIZE    = "${var.file_upload_size_limit}M"
    PHP_POST_MAX_SIZE          = "${var.file_upload_size_limit}M"
    PHP_MAX_EXECUTION_TIME     = "300"
    PHP_MAX_INPUT_TIME         = "300"
  }

  logs {
    detailed_error_messages = true
    failed_request_tracing  = true
    http_logs {
      file_system {
        retention_in_days = 7
        retention_in_mb   = 35
      }
    }
  }

  identity {
    type = "SystemAssigned"
  }
}

# Storage Account Backup Configuration
# Note: MySQL Flexible Server already has automatic backups (configured in existing server)
# For blob storage, we'll enable versioning and soft delete instead of Azure Backup

# Enable blob versioning and soft delete for production storage
resource "azurerm_storage_management_policy" "bookstack" {
  storage_account_id = azurerm_storage_account.bookstack.id

  rule {
    name    = "backup_policy"
    enabled = true
    filters {
      prefix_match = ["uploads/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 90
      }
      version {
        delete_after_days_since_creation = 30
      }
      snapshot {
        delete_after_days_since_creation_greater_than = 7
      }
    }
  }
}

# Enable blob versioning and soft delete for staging storage
resource "azurerm_storage_management_policy" "bookstack_stage" {
  storage_account_id = azurerm_storage_account.bookstack_stage.id

  rule {
    name    = "backup_policy"
    enabled = true
    filters {
      prefix_match = ["uploads/"]
      blob_types   = ["blockBlob"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 30
      }
      version {
        delete_after_days_since_creation = 14
      }
      snapshot {
        delete_after_days_since_creation_greater_than = 3
      }
    }
  }
}


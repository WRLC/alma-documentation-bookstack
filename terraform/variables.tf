# Existing Resources
variable "existing_app_service_plan_name" {
  description = "Name of the existing App Service Plan"
  type        = string
}

variable "existing_app_service_plan_rg" {
  description = "Resource group of the existing App Service Plan"
  type        = string
}

variable "existing_log_analytics_workspace_name" {
  description = "Name of the existing Log Analytics workspace"
  type        = string
}

variable "existing_log_analytics_workspace_rg" {
  description = "Resource group of the existing Log Analytics workspace"
  type        = string
}

variable "existing_mysql_server_name" {
  description = "Name of the existing MySQL Flexible Server"
  type        = string
}

variable "existing_mysql_server_rg" {
  description = "Resource group of the existing MySQL Flexible Server"
  type        = string
}

variable "existing_acs_name" {
  description = "Name of the existing Azure Communication Services resource"
  type        = string
}

variable "existing_acs_rg" {
  description = "Resource group of the existing Azure Communication Services resource"
  type        = string
}



# MySQL Database (using existing server)
variable "mysql_admin_username" {
  description = "Administrator username for the existing MySQL server (for creating user)"
  type        = string
}

variable "mysql_admin_password" {
  description = "Administrator password for the existing MySQL server (for creating user)"
  type        = string
  sensitive   = true
}



# BookStack Application Configuration
variable "app_url" {
  description = "Full URL where BookStack will be accessible"
  type        = string
}

variable "app_key" {
  description = "Laravel application key for encryption (generate with 'php artisan key:generate --show')"
  type        = string
  sensitive   = true
  validation {
    condition     = can(regex("^base64:", var.app_key))
    error_message = "App key must be a Laravel key starting with 'base64:'."
  }
}

# Mail Configuration (Azure Communication Services - automated via App Registration)

variable "mail_from_name" {
  description = "Mail from name"
  type        = string
}

variable "mail_from" {
  description = "Mail from address (must be verified in ACS Email domain)"
  type        = string
}

# File Upload Configuration
variable "file_upload_size_limit" {
  description = "File upload size limit"
  type        = string
}

variable "allowed_iframe_sources" {
  description = "Allowed iframe sources for embedded content"
  type        = string
}
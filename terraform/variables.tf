variable "azure_service_plan_name" {
  type = string
  description = "Existing Azure app service plan to use"
}

variable "azure_service_plan_rg_name" {
  type = string
  description = "Resource group for the existing Azure app service plan"
}

variable "azure_mysql_flexible_server_name" {
  type = string
  description = "Existing Azure MySQL flexible server to use"
}

variable "azure_mysql_flexible_server_rg_name" {
  type = string
  description = "Resource group for the existing Azure MySQL flexible server"
}

variable "azure_log_analytics_workspace_name" {
  type = string
  description = "Existing Azure log analytics workspace to use"
}

variable "azure_log_analytics_workspace_rg_name" {
  type = string
  description = "Resource group for the existing log analytics workspace"
}

variable "mysql_admin_username" {
  type = string
  description = "Admin username for the existing Azure MySQL flexible server"
}

variable "mysql_admin_password" {
  type = string
  description = "Admin password for the existing Azure MySQL flexible server"
  sensitive = true
}

variable "bookstack_app_key" {
  type = string
  description = "Application key for BookStack"
  sensitive = true
}

variable "smtp_username" {
  type = string
  description = "SMTP username"
  sensitive = true
}
variable "smtp_password" {
  type = string
  description = "SMTP password"
  sensitive = true
}

variable "mail_from" {
  type = string
  description = "Email from address"
}

variable "mail_from_name" {
  type = string
  description = "Email from display name"
}

variable "allowed_iframe_source" {
  type = string
  description = "Allowed domain sources for iframes"
}
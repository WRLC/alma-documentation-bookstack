terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.0"
    }
    mysql = {
      source  = "petoju/mysql"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = "c6b4ce21-1b32-4550-906b-5ab71cdc6337"
}

provider "mysql" {
  endpoint = data.azurerm_mysql_flexible_server.existing.fqdn
  username = var.mysql_admin_username
  password = var.mysql_admin_password
}
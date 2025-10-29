terraform {
  required_version = ">= 1.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "vr-campus-viewer"
}

variable "environment" {
  description = "Environment"
  type        = string
  default     = "dev"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "acr_sku" {
  description = "ACR SKU"
  type        = string
  default     = "Basic"
}

variable "app_service_sku" {
  description = "App Service SKU"
  type        = string
  default     = "B1"
}

resource "azurerm_resource_group" "main" {
  name     = "rg-${var.project_name}-${var.environment}"
  location = var.location
  tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

resource "azurerm_container_registry" "acr" {
  name                = "acr${replace(var.project_name, "-", "")}${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = true
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "azurerm_service_plan" "main" {
  name                = "asp-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = var.app_service_sku
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

resource "azurerm_linux_web_app" "main" {
  name                = "app-${var.project_name}-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id
  site_config {
    always_on = true
    application_stack {
      docker_image_name   = "nginx:alpine"
      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"
    }
    cors {
      allowed_origins = ["*"]
    }
  }
  app_settings = {
    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"
    "DOCKER_REGISTRY_SERVER_URL"          = "https://${azurerm_container_registry.acr.login_server}"
    "DOCKER_REGISTRY_SERVER_USERNAME"     = azurerm_container_registry.acr.admin_username
    "DOCKER_REGISTRY_SERVER_PASSWORD"     = azurerm_container_registry.acr.admin_password
    "WEBSITES_PORT"                       = "80"
  }
  https_only = true
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

output "resource_group_name" {
  value       = azurerm_resource_group.main.name
  description = "Resource Group name"
}

output "acr_login_server" {
  value       = azurerm_container_registry.acr.login_server
  description = "ACR Login Server URL"
}

output "acr_admin_username" {
  value       = azurerm_container_registry.acr.admin_username
  description = "ACR Admin Username"
  sensitive   = true
}

output "acr_admin_password" {
  value       = azurerm_container_registry.acr.admin_password
  description = "ACR Admin Password"
  sensitive   = true
}

output "web_app_url" {
  value       = "https://${azurerm_linux_web_app.main.default_hostname}"
  description = "Web App URL"
}

output "web_app_name" {
  value       = azurerm_linux_web_app.main.name
  description = "Web App Name"
}

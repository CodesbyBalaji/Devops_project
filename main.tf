terraform {terraform {

  required_providers {  required_version = ">= 1.0"

    azurerm = {  required_providers {

      source  = "hashicorp/azurerm"    azurerm = {

      version = "~> 3.0"      source  = "hashicorp/azurerm"

    }      version = "~> 3.0"

  }    }

}  }

}

provider "azurerm" {

  features {}provider "azurerm" {

  subscription_id = "3b193060-7732-4b0d-a8d5-399332a729f0"  features {}

  tenant_id       = "512c852c-3bb5-46d3-a873-98a9c37927b0"  skip_provider_registration = true

}}



variable "project_name" {variable "project_name" {

  description = "Project name used for resource naming"  description = "Project name"

  type        = string  type        = string

}  default     = "vr-campus-viewer"

}

variable "environment" {

  description = "Environment (dev, staging, prod)"variable "environment" {

  type        = string  description = "Environment"

}  type        = string

  default     = "dev"

variable "location" {}

  description = "Azure region for resources"

  type        = stringvariable "location" {

}  description = "Azure region"

  type        = string

variable "acr_sku" {  default     = "East US"

  description = "ACR SKU tier"}

  type        = string

  default     = "Basic"variable "acr_sku" {

}  description = "ACR SKU"

  type        = string

variable "app_service_sku" {  default     = "Basic"

  description = "App Service Plan SKU"}

  type        = string

  default     = "B1"variable "app_service_sku" {

}  description = "App Service SKU"

  type        = string

locals {  default     = "B1"

  resource_group_name = "rg-${var.project_name}-${var.environment}"}

  acr_name            = "acr${replace(var.project_name, "-", "")}${var.environment}"

  app_service_name    = "app-${var.project_name}-${var.environment}"resource "azurerm_resource_group" "main" {

  service_plan_name   = "plan-${var.project_name}-${var.environment}"  name     = "rg-${var.project_name}-${var.environment}"

}  location = var.location

  tags = {

resource "azurerm_resource_group" "main" {    Environment = var.environment

  name     = local.resource_group_name    Project     = var.project_name

  location = var.location    ManagedBy   = "Terraform"

  }

  tags = {}

    Environment = var.environment

    Project     = var.project_nameresource "azurerm_container_registry" "acr" {

    ManagedBy   = "Terraform"  name                = "acr${replace(var.project_name, "-", "")}${var.environment}"

  }  resource_group_name = azurerm_resource_group.main.name

}  location            = azurerm_resource_group.main.location

  sku                 = var.acr_sku

resource "azurerm_container_registry" "acr" {  admin_enabled       = true

  name                = local.acr_name  tags = {

  resource_group_name = azurerm_resource_group.main.name    Environment = var.environment

  location            = azurerm_resource_group.main.location    Project     = var.project_name

  sku                 = var.acr_sku  }

  admin_enabled       = true}



  tags = {resource "azurerm_service_plan" "main" {

    Environment = var.environment  name                = "asp-${var.project_name}-${var.environment}"

    Project     = var.project_name  resource_group_name = azurerm_resource_group.main.name

    ManagedBy   = "Terraform"  location            = azurerm_resource_group.main.location

  }  os_type             = "Linux"

}  sku_name            = var.app_service_sku

  tags = {

resource "azurerm_service_plan" "main" {    Environment = var.environment

  name                = local.service_plan_name    Project     = var.project_name

  resource_group_name = azurerm_resource_group.main.name  }

  location            = azurerm_resource_group.main.location}

  os_type             = "Linux"

  sku_name            = var.app_service_skuresource "azurerm_linux_web_app" "main" {

  name                = "app-${var.project_name}-${var.environment}"

  tags = {  resource_group_name = azurerm_resource_group.main.name

    Environment = var.environment  location            = azurerm_resource_group.main.location

    Project     = var.project_name  service_plan_id     = azurerm_service_plan.main.id

    ManagedBy   = "Terraform"  site_config {

  }    always_on = true

}    application_stack {

      docker_image_name   = "nginx:alpine"

resource "azurerm_linux_web_app" "main" {      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"

  name                = local.app_service_name    }

  resource_group_name = azurerm_resource_group.main.name    cors {

  location            = azurerm_resource_group.main.location      allowed_origins = ["*"]

  service_plan_id     = azurerm_service_plan.main.id    }

  }

  site_config {  app_settings = {

    always_on = false    "WEBSITES_ENABLE_APP_SERVICE_STORAGE" = "false"

        "DOCKER_REGISTRY_SERVER_URL"          = "https://${azurerm_container_registry.acr.login_server}"

    application_stack {    "DOCKER_REGISTRY_SERVER_USERNAME"     = azurerm_container_registry.acr.admin_username

      docker_image_name   = "vr-campus-viewer:v1"    "DOCKER_REGISTRY_SERVER_PASSWORD"     = azurerm_container_registry.acr.admin_password

      docker_registry_url = "https://${azurerm_container_registry.acr.login_server}"    "WEBSITES_PORT"                       = "80"

    }  }

  }  https_only = true

  tags = {

  app_settings = {    Environment = var.environment

    WEBSITES_ENABLE_APP_SERVICE_STORAGE = "false"    Project     = var.project_name

    DOCKER_REGISTRY_SERVER_URL          = "https://${azurerm_container_registry.acr.login_server}"  }

    DOCKER_REGISTRY_SERVER_USERNAME     = azurerm_container_registry.acr.admin_username}

    DOCKER_REGISTRY_SERVER_PASSWORD     = azurerm_container_registry.acr.admin_password

  }output "resource_group_name" {

  value       = azurerm_resource_group.main.name

  tags = {  description = "Resource Group name"

    Environment = var.environment}

    Project     = var.project_name

    ManagedBy   = "Terraform"output "acr_login_server" {

  }  value       = azurerm_container_registry.acr.login_server

}  description = "ACR Login Server URL"

}

output "resource_group_name" {

  value = azurerm_resource_group.main.nameoutput "acr_admin_username" {

}  value       = azurerm_container_registry.acr.admin_username

  description = "ACR Admin Username"

output "acr_login_server" {  sensitive   = true

  value = azurerm_container_registry.acr.login_server}

}

output "acr_admin_password" {

output "acr_admin_username" {  value       = azurerm_container_registry.acr.admin_password

  value     = azurerm_container_registry.acr.admin_username  description = "ACR Admin Password"

  sensitive = true  sensitive   = true

}}



output "acr_admin_password" {output "web_app_url" {

  value     = azurerm_container_registry.acr.admin_password  value       = "https://${azurerm_linux_web_app.main.default_hostname}"

  sensitive = true  description = "Web App URL"

}}



output "web_app_url" {output "web_app_name" {

  value = "https://${azurerm_linux_web_app.main.default_hostname}"  value       = azurerm_linux_web_app.main.name

}  description = "Web App Name"

}

output "web_app_name" {
  value = azurerm_linux_web_app.main.name
}

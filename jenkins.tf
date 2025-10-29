# Jenkins Server Infrastructure
# This creates a VM to host Jenkins for CI/CD automation

# Virtual Network for Jenkins VM
resource "azurerm_virtual_network" "jenkins" {
  name                = "vnet-jenkins-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Component   = "Jenkins"
  }
}

# Subnet for Jenkins VM
resource "azurerm_subnet" "jenkins" {
  name                 = "subnet-jenkins"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.jenkins.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Public IP for Jenkins VM
resource "azurerm_public_ip" "jenkins" {
  name                = "pip-jenkins-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Component   = "Jenkins"
  }
}

# Network Security Group for Jenkins
resource "azurerm_network_security_group" "jenkins" {
  name                = "nsg-jenkins-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  # Allow SSH
  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # Allow Jenkins Web UI (8080)
  security_rule {
    name                       = "Jenkins"
    priority                   = 1002
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    destination_address_prefix = "*"
    source_address_prefix      = "*"
  }

  # Allow HTTPS
  security_rule {
    name                       = "HTTPS"
    priority                   = 1003
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Network Interface for Jenkins VM
resource "azurerm_network_interface" "jenkins" {
  name                = "nic-jenkins-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.jenkins.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.jenkins.id
  }

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# Associate NSG with Network Interface
resource "azurerm_network_interface_security_group_association" "jenkins" {
  network_interface_id      = azurerm_network_interface.jenkins.id
  network_security_group_id = azurerm_network_security_group.jenkins.id
}

# Jenkins VM
resource "azurerm_linux_virtual_machine" "jenkins" {
  name                = "vm-jenkins-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  size                = var.jenkins_vm_size
  admin_username      = var.jenkins_admin_username

  network_interface_ids = [
    azurerm_network_interface.jenkins.id,
  ]

  admin_ssh_key {
    username   = var.jenkins_admin_username
    public_key = var.jenkins_ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    disk_size_gb         = 30
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Custom data script to install Jenkins, Docker, Azure CLI
  custom_data = base64encode(templatefile("${path.module}/jenkins-install.sh", {
    acr_name           = azurerm_container_registry.acr.name
    acr_login_server   = azurerm_container_registry.acr.login_server
    resource_group     = azurerm_resource_group.main.name
    web_app_name       = azurerm_linux_web_app.main.name
    subscription_id    = var.subscription_id
    tenant_id          = var.tenant_id
    client_id          = var.client_id
    client_secret      = var.client_secret
  }))

  tags = {
    Environment = var.environment
    Project     = var.project_name
    Component   = "Jenkins"
  }
}

# Outputs for Jenkins
output "jenkins_public_ip" {
  value       = azurerm_public_ip.jenkins.ip_address
  description = "Jenkins server public IP address"
}

output "jenkins_url" {
  value       = "http://${azurerm_public_ip.jenkins.ip_address}:8080"
  description = "Jenkins Web UI URL"
}

output "jenkins_ssh_command" {
  value       = "ssh ${var.jenkins_admin_username}@${azurerm_public_ip.jenkins.ip_address}"
  description = "SSH command to connect to Jenkins VM"
}

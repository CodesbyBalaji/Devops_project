#!/bin/bash
# Jenkins Installation Script for Azure VM
# This script installs Jenkins, Docker, Azure CLI, and configures everything

set -e

echo "=== Starting Jenkins Installation ==="

# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install Java (required for Jenkins)
echo "Installing Java..."
sudo apt-get install -y openjdk-17-jdk

# Install Jenkins
echo "Installing Jenkins..."
sudo wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key
echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | sudo tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null
sudo apt-get update
sudo apt-get install -y jenkins

# Install Docker
echo "Installing Docker..."
sudo apt-get install -y ca-certificates curl gnupg lsb-release
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Add jenkins user to docker group
sudo usermod -aG docker jenkins

# Install Azure CLI
echo "Installing Azure CLI..."
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Start Jenkins
echo "Starting Jenkins..."
sudo systemctl start jenkins
sudo systemctl enable jenkins

# Start Docker
sudo systemctl start docker
sudo systemctl enable docker

# Configure Jenkins credentials file
echo "Configuring Azure credentials..."
sudo mkdir -p /var/lib/jenkins/azure-credentials
sudo cat > /var/lib/jenkins/azure-credentials/config.txt <<EOF
ACR_NAME=${acr_name}
ACR_LOGIN_SERVER=${acr_login_server}
RESOURCE_GROUP=${resource_group}
WEB_APP_NAME=${web_app_name}
SUBSCRIPTION_ID=${subscription_id}
TENANT_ID=${tenant_id}
CLIENT_ID=${client_id}
CLIENT_SECRET=${client_secret}
EOF
sudo chown -R jenkins:jenkins /var/lib/jenkins/azure-credentials
sudo chmod 600 /var/lib/jenkins/azure-credentials/config.txt

# Get initial admin password
sleep 30
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    INITIAL_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
    echo "=== Jenkins Installation Complete ==="
    echo "Initial Admin Password: $INITIAL_PASSWORD"
    echo "Save this password!"
else
    echo "Waiting for Jenkins to initialize..."
    sleep 30
    INITIAL_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)
    echo "Initial Admin Password: $INITIAL_PASSWORD"
fi

# Create a file with the password for easy retrieval
echo "$INITIAL_PASSWORD" | sudo tee /home/azureuser/jenkins-initial-password.txt
sudo chmod 644 /home/azureuser/jenkins-initial-password.txt

echo "=== Installation Summary ==="
echo "Jenkins URL: http://$(curl -s ifconfig.me):8080"
echo "Initial Password saved to: /home/azureuser/jenkins-initial-password.txt"
echo "Azure CLI: Installed"
echo "Docker: Installed"
echo "Next: Access Jenkins UI and complete setup wizard"

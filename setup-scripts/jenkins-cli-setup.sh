#!/bin/bash
# Jenkins CLI Automation Script
# This script automates Jenkins initial setup using CLI

set -e

JENKINS_URL="http://localhost:8080"
JENKINS_CLI="/tmp/jenkins-cli.jar"
ADMIN_PASSWORD=$(sudo cat /var/lib/jenkins/secrets/initialAdminPassword)

echo "=================================================="
echo "Jenkins CLI Setup Automation"
echo "=================================================="
echo ""

# Function to run Jenkins CLI commands
run_jenkins_cli() {
    java -jar $JENKINS_CLI -s $JENKINS_URL -auth admin:$ADMIN_PASSWORD "$@"
}

# Wait for Jenkins to be fully ready
echo "⏳ Waiting for Jenkins to be fully ready..."
until curl -sf $JENKINS_URL/api/json >/dev/null 2>&1; do
    echo "   Waiting for Jenkins..."
    sleep 5
done
echo "✅ Jenkins is ready!"
echo ""

# Skip initial setup wizard
echo "🔧 Configuring Jenkins to skip setup wizard..."
sudo mkdir -p /var/lib/jenkins/init.groovy.d
sudo tee /var/lib/jenkins/init.groovy.d/basic-security.groovy > /dev/null <<'EOF'
#!groovy

import jenkins.model.*
import hudson.security.*
import jenkins.install.*

def instance = Jenkins.getInstance()

// Skip setup wizard
instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)

// Create admin user
def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount("admin", "admin123")
instance.setSecurityRealm(hudsonRealm)

// Set authorization strategy
def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

instance.save()
println("Jenkins basic security configured!")
EOF

echo "✅ Setup wizard bypass configured"
echo ""

# Install essential plugins
echo "📦 Installing essential plugins..."
echo "   This will take several minutes..."

# List of plugins to install
PLUGINS=(
    "workflow-aggregator"
    "docker-workflow"
    "docker-plugin"
    "github"
    "git"
    "credentials-binding"
    "azure-cli"
    "cloudbees-folder"
    "antisamy-markup-formatter"
    "build-timeout"
    "timestamper"
    "ws-cleanup"
    "pipeline-stage-view"
    "ssh-slaves"
)

# Restart Jenkins to apply initial configuration
echo "🔄 Restarting Jenkins to apply configuration..."
sudo systemctl restart jenkins

# Wait for Jenkins to restart
echo "⏳ Waiting for Jenkins to restart (60 seconds)..."
sleep 60

until curl -sf $JENKINS_URL/api/json >/dev/null 2>&1; do
    echo "   Still waiting for Jenkins..."
    sleep 5
done

echo "✅ Jenkins restarted successfully!"
echo ""

# Try to install plugins via CLI (may require manual installation if CLI auth fails)
echo "📦 Attempting to install plugins..."
for plugin in "${PLUGINS[@]}"; do
    echo "   Installing: $plugin"
    run_jenkins_cli install-plugin "$plugin" || echo "   ⚠ Failed to install $plugin (may need manual installation)"
done

echo ""
echo "=================================================="
echo "✅ Jenkins CLI Setup Complete!"
echo "=================================================="
echo ""
echo "📋 Next Steps:"
echo ""
echo "1. Access Jenkins UI: http://13.70.38.89:8080"
echo "2. Login credentials:"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo "3. Complete remaining setup:"
echo "   - Verify plugins installed"
echo "   - Add Azure Service Principal credentials"
echo "   - Add ACR credentials"
echo "   - Create pipeline job"
echo "   - Setup GitHub webhook"
echo ""
echo "4. Initial admin password file will be removed after first login"
echo ""
echo "=================================================="

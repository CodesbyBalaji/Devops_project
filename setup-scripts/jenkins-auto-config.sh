#!/bin/bash
# Jenkins Setup via Configuration Files
# This script bypasses the setup wizard by directly configuring Jenkins

set -e

echo "=================================================="
echo "Jenkins Automated Configuration"
echo "=================================================="
echo ""

# Create admin user and skip setup wizard
echo "🔧 Creating Jenkins configuration..."

# Create the basic security groovy script
sudo tee /var/lib/jenkins/init.groovy.d/01-basic-security.groovy > /dev/null <<'EOF'
#!groovy
import jenkins.model.*
import hudson.security.*
import jenkins.install.InstallState

def instance = Jenkins.getInstance()

println("--> Creating admin user")

def hudsonRealm = new HudsonPrivateSecurityRealm(false)
hudsonRealm.createAccount('admin', 'admin123')
instance.setSecurityRealm(hudsonRealm)

def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
strategy.setAllowAnonymousRead(false)
instance.setAuthorizationStrategy(strategy)

// Mark setup as complete
instance.setInstallState(InstallState.INITIAL_SETUP_COMPLETED)

instance.save()

println("--> Admin user created, setup wizard skipped")
EOF

# Change ownership to jenkins user
sudo chown jenkins:jenkins /var/lib/jenkins/init.groovy.d/01-basic-security.groovy

echo "✅ Configuration file created"
echo ""

# Restart Jenkins to apply configuration
echo "🔄 Restarting Jenkins to apply configuration..."
sudo systemctl restart jenkins

echo "⏳ Waiting for Jenkins to start (this takes about 60 seconds)..."
sleep 70

# Wait for Jenkins to be responsive
MAX_ATTEMPTS=30
ATTEMPT=0
until curl -sf http://localhost:8080 > /dev/null 2>&1; do
    ATTEMPT=$((ATTEMPT + 1))
    if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
        echo "❌ Jenkins did not start in time"
        exit 1
    fi
    echo "   Attempt $ATTEMPT/$MAX_ATTEMPTS - waiting for Jenkins..."
    sleep 5
done

echo "✅ Jenkins is running!"
echo ""

# Install plugins using Jenkins plugin installation mechanism
echo "📦 Installing plugins..."
echo "   Creating plugin installation script..."

sudo tee /var/lib/jenkins/init.groovy.d/02-install-plugins.groovy > /dev/null <<'EOF'
#!groovy
import jenkins.model.*
import java.util.logging.Logger

def logger = Logger.getLogger("")
def installed = false
def initialized = false

def pluginsList = [
    "workflow-aggregator",
    "docker-workflow", 
    "github",
    "git",
    "credentials-binding",
    "pipeline-stage-view",
    "timestamper",
    "ws-cleanup"
]

logger.info("Installing plugins...")

def instance = Jenkins.getInstance()
def pm = instance.getPluginManager()
def uc = instance.getUpdateCenter()

// Install plugins
pluginsList.each { pluginName ->
    if (!pm.getPlugin(pluginName)) {
        logger.info("Installing plugin: ${pluginName}")
        def plugin = uc.getPlugin(pluginName)
        if (plugin) {
            plugin.deploy()
            installed = true
        }
    }
}

if (installed) {
    logger.info("Plugins installed, restart required")
} else {
    logger.info("No new plugins to install")
}
EOF

sudo chown jenkins:jenkins /var/lib/jenkins/init.groovy.d/02-install-plugins.groovy

echo "✅ Plugin installation configured"
echo ""

# Check if initial password file should be removed
if [ -f /var/lib/jenkins/secrets/initialAdminPassword ]; then
    echo "🔑 Initial admin password file still exists (will be removed after first web login)"
fi

echo ""
echo "=================================================="
echo "✅ Jenkins Configuration Complete!"
echo "=================================================="
echo ""
echo "📋 Access Information:"
echo ""
echo "   URL: http://13.70.38.89:8080"
echo "   Username: admin"
echo "   Password: admin123"
echo ""
echo "⚠️  IMPORTANT: Change the default password after first login!"
echo ""
echo "📦 Plugins will install automatically on next restart"
echo "   To install plugins now: sudo systemctl restart jenkins"
echo ""
echo "=================================================="

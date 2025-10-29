#!/bin/bash
# Jenkins Plugin Installation Script

echo "=================================================="
echo "Phase 3: Installing Jenkins Plugins"
echo "=================================================="
echo ""

JENKINS_URL="http://localhost:8080"
JENKINS_USER="admin"
JENKINS_PASSWORD="admin123"

# Required plugins for the pipeline
PLUGINS=(
    "workflow-aggregator"
    "docker-workflow"
    "github"
    "git"
    "credentials-binding"
    "pipeline-stage-view"
    "timestamper"
    "ws-cleanup"
)

echo "Checking Jenkins CLI availability..."
if [ ! -f /tmp/jenkins-cli.jar ]; then
    echo "Downloading Jenkins CLI..."
    wget -q $JENKINS_URL/jnlpJars/jenkins-cli.jar -O /tmp/jenkins-cli.jar
fi

echo "✅ Jenkins CLI ready"
echo ""

echo "Installing required plugins..."
echo ""

for plugin in "${PLUGINS[@]}"; do
    echo "📦 Installing: $plugin"
    java -jar /tmp/jenkins-cli.jar -s $JENKINS_URL \
        -auth $JENKINS_USER:$JENKINS_PASSWORD \
        install-plugin $plugin -restart 2>&1 | grep -v "^$" || true
done

echo ""
echo "✅ Plugin installation complete!"
echo "Note: Jenkins will restart automatically to activate plugins"
echo ""

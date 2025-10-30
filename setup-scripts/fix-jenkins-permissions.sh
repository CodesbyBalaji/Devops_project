#!/bin/bash
# Script to fix Jenkins permissions and configuration issues

echo "=== Jenkins Permission Fix Script ==="
echo "Checking Jenkins configuration..."

# 1. Check if Jenkins is running
if ! systemctl is-active --quiet jenkins; then
    echo "ERROR: Jenkins is not running. Starting Jenkins..."
    sudo systemctl start jenkins
    sleep 30
fi

# 2. Backup current Jenkins configuration
echo "Creating backup of Jenkins configuration..."
sudo cp /var/lib/jenkins/config.xml /var/lib/jenkins/config.xml.backup.$(date +%Y%m%d_%H%M%S)

# 3. Check admin user permissions
echo "Checking admin user configuration..."
if [ -f /var/lib/jenkins/users/admin*/config.xml ]; then
    echo "Admin user configuration found"
    sudo cat /var/lib/jenkins/users/admin*/config.xml | grep -A 5 "permissions"
else
    echo "WARNING: Admin user configuration not found"
fi

# 4. Disable security temporarily (ONLY for debugging - re-enable after)
# Uncomment the following lines ONLY if you want to temporarily disable security
# echo "CAUTION: This would disable security temporarily"
# echo "To disable security, run manually:"
# echo "  sudo sed -i 's/<useSecurity>true<\/useSecurity>/<useSecurity>false<\/useSecurity>/' /var/lib/jenkins/config.xml"
# echo "  sudo systemctl restart jenkins"

# 5. Check Jenkins version and plugin status
echo ""
echo "Jenkins Installation Details:"
if [ -f /var/lib/jenkins/jenkins.install.InstallUtil.lastExecVersion ]; then
    echo "Jenkins Version: $(cat /var/lib/jenkins/jenkins.install.InstallUtil.lastExecVersion)"
fi

# 6. Check job configuration permissions
echo ""
echo "Checking job configuration file permissions..."
JOB_DIR="/var/lib/jenkins/jobs/vr-campus-viewer-pipeline"
if [ -d "$JOB_DIR" ]; then
    ls -la "$JOB_DIR/"
    echo ""
    echo "Job config.xml permissions:"
    ls -la "$JOB_DIR/config.xml"
else
    echo "WARNING: Job directory not found"
fi

# 7. Fix ownership if needed
echo ""
echo "Checking Jenkins file ownership..."
WRONG_PERMS=$(find /var/lib/jenkins -not -user jenkins 2>/dev/null | wc -l)
if [ $WRONG_PERMS -gt 0 ]; then
    echo "WARNING: Found $WRONG_PERMS files with incorrect ownership"
    echo "To fix, run: sudo chown -R jenkins:jenkins /var/lib/jenkins"
else
    echo "File ownership looks good"
fi

# 8. Check Jenkins logs for errors
echo ""
echo "Recent Jenkins logs (last 20 lines):"
sudo tail -20 /var/log/jenkins/jenkins.log

echo ""
echo "=== Configuration Check Complete ==="
echo ""
echo "RECOMMENDED ACTIONS:"
echo "1. If ownership issues found, run: sudo chown -R jenkins:jenkins /var/lib/jenkins"
echo "2. Check Jenkins logs for specific errors: sudo tail -f /var/log/jenkins/jenkins.log"
echo "3. Try accessing Jenkins UI again after restart"
echo "4. If still having issues, check: http://13.70.38.89:8080/manage"

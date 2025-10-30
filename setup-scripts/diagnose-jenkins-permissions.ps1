# Jenkins Permission Diagnosis Script
# This script helps diagnose and fix Jenkins permission issues

Write-Host "=== Jenkins Permission Diagnosis ===" -ForegroundColor Cyan
Write-Host ""

# Configuration
$JENKINS_IP = "13.70.38.89"
$JENKINS_PORT = "8080"
$JENKINS_URL = "http://" + $JENKINS_IP + ":" + $JENKINS_PORT

# 1. Check if Jenkins UI is accessible
Write-Host "1. Checking Jenkins UI accessibility..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $JENKINS_URL -Method Get -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "   ✓ Jenkins UI is accessible" -ForegroundColor Green
    }
} catch {
    Write-Host "   ✗ Jenkins UI is not accessible yet" -ForegroundColor Red
    Write-Host "   Waiting 30 more seconds..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
}

# 2. Get VM details
Write-Host ""
Write-Host "2. Getting VM details..." -ForegroundColor Yellow
$vmJson = az vm show --name vm-jenkins-dev --resource-group rg-vr-campus-viewer-dev --query "{Name:name}" -o json
$vm = $vmJson | ConvertFrom-Json
Write-Host "   VM Name: $($vm.Name)" -ForegroundColor Cyan
Write-Host "   Public IP: $JENKINS_IP" -ForegroundColor Cyan

# 3. Instructions for SSH access
Write-Host ""
Write-Host "3. To diagnose Jenkins permissions, you need SSH access:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   SSH Command:" -ForegroundColor Cyan
Write-Host "   ssh -i ~/.ssh/jenkins-key jenkinsadmin@$JENKINS_IP" -ForegroundColor White
Write-Host ""

# 4. Commands to run on the server
Write-Host "4. Once connected via SSH, run these commands:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   # Upload and run the diagnostic script:" -ForegroundColor Cyan
Write-Host "   chmod +x /tmp/fix-jenkins-permissions.sh" -ForegroundColor White
Write-Host "   sudo /tmp/fix-jenkins-permissions.sh" -ForegroundColor White
Write-Host ""
Write-Host "   # Or run these commands directly:" -ForegroundColor Cyan
Write-Host "   sudo systemctl status jenkins" -ForegroundColor White
Write-Host "   sudo tail -50 /var/log/jenkins/jenkins.log" -ForegroundColor White
Write-Host "   sudo ls -la /var/lib/jenkins/jobs/vr-campus-viewer-pipeline/" -ForegroundColor White
Write-Host "   sudo find /var/lib/jenkins -not -user jenkins" -ForegroundColor White
Write-Host ""

# 5. Common fixes
Write-Host "5. Common fixes to try:" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Option A: Fix file ownership" -ForegroundColor Cyan
Write-Host "   sudo chown -R jenkins:jenkins /var/lib/jenkins" -ForegroundColor White
Write-Host "   sudo systemctl restart jenkins" -ForegroundColor White
Write-Host ""
Write-Host "   Option B: Temporarily disable CSRF protection" -ForegroundColor Cyan
Write-Host "   1. Go to: $JENKINS_URL/manage" -ForegroundColor White
Write-Host "   2. Click 'Configure Global Security'" -ForegroundColor White
Write-Host "   3. Uncheck 'Prevent Cross Site Request Forgery exploits'" -ForegroundColor White
Write-Host "   4. Save and try configuring the job again" -ForegroundColor White
Write-Host "   5. Re-enable CSRF after fixing the job configuration" -ForegroundColor White
Write-Host ""
Write-Host "   Option C: Use Jenkins CLI" -ForegroundColor Cyan
Write-Host "   # Download Jenkins CLI JAR" -ForegroundColor White
Write-Host "   wget $JENKINS_URL/jnlpJars/jenkins-cli.jar" -ForegroundColor White
Write-Host "   # Get job XML" -ForegroundColor White
Write-Host "   java -jar jenkins-cli.jar -s $JENKINS_URL get-job vr-campus-viewer-pipeline > job.xml" -ForegroundColor White
Write-Host "   # Edit job.xml to remove <hudson.plugins.git.extensions.impl.CloneOption>" -ForegroundColor White
Write-Host "   # Update job" -ForegroundColor White
Write-Host "   java -jar jenkins-cli.jar -s $JENKINS_URL update-job vr-campus-viewer-pipeline < job.xml" -ForegroundColor White
Write-Host ""

# 6. Alternative: Update via Jenkins REST API
Write-Host "6. Alternative: Update job via Jenkins REST API (if you have API token):" -ForegroundColor Yellow
Write-Host ""
Write-Host "   # Get current job config" -ForegroundColor Cyan
Write-Host "   Invoke-WebRequest -Uri '$JENKINS_URL/job/vr-campus-viewer-pipeline/config.xml' -Method Get -OutFile job.xml" -ForegroundColor White
Write-Host "   # Edit job.xml to remove lightweight checkout section" -ForegroundColor White
Write-Host "   # Post updated config" -ForegroundColor White
Write-Host "   Invoke-WebRequest -Uri '$JENKINS_URL/job/vr-campus-viewer-pipeline/config.xml' -Method Post -InFile job.xml -ContentType 'text/xml'" -ForegroundColor White
Write-Host ""

# 7. Check current admin credentials
Write-Host "7. Admin Credentials (from JENKINS_CREDENTIALS.txt):" -ForegroundColor Yellow
if (Test-Path "JENKINS_CREDENTIALS.txt") {
    Write-Host ""
    Get-Content "JENKINS_CREDENTIALS.txt"
    Write-Host ""
} else {
    Write-Host "   JENKINS_CREDENTIALS.txt not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Try accessing Jenkins UI: $JENKINS_URL" -ForegroundColor White
Write-Host "2. If permission error persists, use SSH to run diagnostic script" -ForegroundColor White
Write-Host "3. Try Option B (disable CSRF temporarily) from Jenkins UI" -ForegroundColor White
Write-Host "4. Or use Jenkins CLI (Option C) to update job configuration" -ForegroundColor White
Write-Host ""

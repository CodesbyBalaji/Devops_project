# Jenkins Status Check Script

$JENKINS_IP = "13.70.38.89"
$JENKINS_PORT = "8080"
$JENKINS_URL = "http://${JENKINS_IP}:${JENKINS_PORT}"

Write-Host "=== Jenkins Status Check ===" -ForegroundColor Cyan
Write-Host ""

# Check if Jenkins is accessible
Write-Host "Checking Jenkins UI..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri $JENKINS_URL -UseBasicParsing -TimeoutSec 10
    Write-Host "SUCCESS: Jenkins is accessible (Status: $($response.StatusCode))" -ForegroundColor Green
} catch {
    Write-Host "WARNING: Jenkins is not accessible yet" -ForegroundColor Red
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Admin Credentials ===" -ForegroundColor Cyan
if (Test-Path "JENKINS_CREDENTIALS.txt") {
    Get-Content "JENKINS_CREDENTIALS.txt"
} else {
    Write-Host "JENKINS_CREDENTIALS.txt not found" -ForegroundColor Red
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Cyan
Write-Host "1. Access Jenkins: $JENKINS_URL" -ForegroundColor White
Write-Host "2. Try disabling CSRF protection temporarily:" -ForegroundColor White
Write-Host "   - Go to: $JENKINS_URL/manage" -ForegroundColor Gray
Write-Host "   - Click 'Configure Global Security'" -ForegroundColor Gray
Write-Host "   - Uncheck 'Prevent Cross Site Request Forgery exploits'" -ForegroundColor Gray
Write-Host "   - Save and try again" -ForegroundColor Gray
Write-Host ""
Write-Host "3. Or use Jenkins CLI to update job config" -ForegroundColor White
Write-Host ""

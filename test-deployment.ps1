# ===================================================================
# Deployment Test Script - VR Campus Viewer
# Tests all components except GitHub webhooks
# ===================================================================

$ErrorActionPreference = "Continue"
$TestResults = @()

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   DEPLOYMENT TEST SUITE" -ForegroundColor Cyan
Write-Host "   $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# ===================================================================
# Test 1: Azure Subscription & Authentication
# ===================================================================
Write-Host "[1/10] Testing Azure Subscription..." -ForegroundColor Yellow
try {
    $account = az account show | ConvertFrom-Json
    if ($account.state -eq "Enabled") {
        Write-Host "✅ Azure subscription active: $($account.name)" -ForegroundColor Green
        Write-Host "   Subscription ID: $($account.id)" -ForegroundColor Gray
        $TestResults += @{Test="Azure Subscription"; Status="PASS"; Details=$account.name}
    } else {
        Write-Host "❌ Azure subscription not enabled" -ForegroundColor Red
        $TestResults += @{Test="Azure Subscription"; Status="FAIL"; Details="Not enabled"}
    }
} catch {
    Write-Host "❌ Cannot verify Azure subscription: $($_.Exception.Message)" -ForegroundColor Red
    $TestResults += @{Test="Azure Subscription"; Status="FAIL"; Details=$_.Exception.Message}
}

# ===================================================================
# Test 2: Resource Group
# ===================================================================
Write-Host "`n[2/10] Testing Resource Group..." -ForegroundColor Yellow
try {
    $rg = az group show --name "rg-vr-campus-viewer-dev" | ConvertFrom-Json
    if ($rg) {
        Write-Host "✅ Resource Group exists: $($rg.name)" -ForegroundColor Green
        Write-Host "   Location: $($rg.location)" -ForegroundColor Gray
        Write-Host "   State: $($rg.properties.provisioningState)" -ForegroundColor Gray
        $TestResults += @{Test="Resource Group"; Status="PASS"; Details=$rg.location}
    }
} catch {
    Write-Host "❌ Resource Group not found" -ForegroundColor Red
    $TestResults += @{Test="Resource Group"; Status="FAIL"; Details="Not found"}
}

# ===================================================================
# Test 3: Azure Container Registry (ACR)
# ===================================================================
Write-Host "`n[3/10] Testing Azure Container Registry..." -ForegroundColor Yellow
try {
    $acr = az acr show --name "acrvrcampusviewerdev" | ConvertFrom-Json
    if ($acr) {
        Write-Host "✅ ACR exists: $($acr.loginServer)" -ForegroundColor Green
        Write-Host "   SKU: $($acr.sku.name)" -ForegroundColor Gray
        Write-Host "   Admin Enabled: $($acr.adminUserEnabled)" -ForegroundColor Gray
        
        # Check for images
        $repos = az acr repository list --name "acrvrcampusviewerdev" | ConvertFrom-Json
        if ($repos) {
            Write-Host "   Repositories: $($repos -join ', ')" -ForegroundColor Gray
            foreach ($repo in $repos) {
                $tags = az acr repository show-tags --name "acrvrcampusviewerdev" --repository $repo | ConvertFrom-Json
                Write-Host "   Tags in ${repo}: $($tags -join ', ')" -ForegroundColor Gray
            }
        }
        $TestResults += @{Test="ACR"; Status="PASS"; Details="$($repos.Count) repositories"}
    }
} catch {
    Write-Host "❌ ACR not found or error" -ForegroundColor Red
    $TestResults += @{Test="ACR"; Status="FAIL"; Details=$_.Exception.Message}
}

# ===================================================================
# Test 4: App Service Plan
# ===================================================================
Write-Host "`n[4/10] Testing App Service Plan..." -ForegroundColor Yellow
try {
    $plan = az appservice plan show --name "asp-vr-campus-viewer-dev" --resource-group "rg-vr-campus-viewer-dev" | ConvertFrom-Json
    if ($plan) {
        Write-Host "✅ App Service Plan exists: $($plan.name)" -ForegroundColor Green
        Write-Host "   SKU: $($plan.sku.name) ($($plan.sku.tier))" -ForegroundColor Gray
        Write-Host "   Capacity: $($plan.sku.capacity)" -ForegroundColor Gray
        Write-Host "   OS: $($plan.kind)" -ForegroundColor Gray
        $TestResults += @{Test="App Service Plan"; Status="PASS"; Details=$plan.sku.name}
    }
} catch {
    Write-Host "❌ App Service Plan not found" -ForegroundColor Red
    $TestResults += @{Test="App Service Plan"; Status="FAIL"; Details="Not found"}
}

# ===================================================================
# Test 5: Web App
# ===================================================================
Write-Host "`n[5/10] Testing Web App..." -ForegroundColor Yellow
try {
    $webapp = az webapp show --name "app-vr-campus-viewer-dev" --resource-group "rg-vr-campus-viewer-dev" | ConvertFrom-Json
    if ($webapp) {
        Write-Host "✅ Web App exists: $($webapp.name)" -ForegroundColor Green
        Write-Host "   State: $($webapp.state)" -ForegroundColor Gray
        Write-Host "   URL: https://$($webapp.defaultHostName)" -ForegroundColor Gray
        Write-Host "   Docker Image: $($webapp.siteConfig.linuxFxVersion)" -ForegroundColor Gray
        Write-Host "   HTTPS Only: $($webapp.httpsOnly)" -ForegroundColor Gray
        $TestResults += @{Test="Web App"; Status="PASS"; Details=$webapp.state}
    }
} catch {
    Write-Host "❌ Web App not found" -ForegroundColor Red
    $TestResults += @{Test="Web App"; Status="FAIL"; Details="Not found"}
}

# ===================================================================
# Test 6: Web App HTTP Response
# ===================================================================
Write-Host "`n[6/10] Testing Web App HTTP Response..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "https://app-vr-campus-viewer-dev.azurewebsites.net" -UseBasicParsing -TimeoutSec 30
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ Web App is responding: HTTP $($response.StatusCode)" -ForegroundColor Green
        Write-Host "   Content Length: $($response.Content.Length) bytes" -ForegroundColor Gray
        Write-Host "   Content Type: $($response.Headers.'Content-Type')" -ForegroundColor Gray
        $TestResults += @{Test="Web App HTTP"; Status="PASS"; Details="HTTP 200"}
    } else {
        Write-Host "⚠️  Web App returned HTTP $($response.StatusCode)" -ForegroundColor Yellow
        $TestResults += @{Test="Web App HTTP"; Status="WARN"; Details="HTTP $($response.StatusCode)"}
    }
} catch {
    Write-Host "❌ Cannot reach Web App: $($_.Exception.Message)" -ForegroundColor Red
    $TestResults += @{Test="Web App HTTP"; Status="FAIL"; Details=$_.Exception.Message}
}

# ===================================================================
# Test 7: Jenkins VM
# ===================================================================
Write-Host "`n[7/10] Testing Jenkins VM..." -ForegroundColor Yellow
try {
    $vm = az vm show --name "vm-jenkins-dev" --resource-group "rg-vr-campus-viewer-dev" | ConvertFrom-Json
    if ($vm) {
        Write-Host "✅ Jenkins VM exists: $($vm.name)" -ForegroundColor Green
        Write-Host "   Size: $($vm.hardwareProfile.vmSize)" -ForegroundColor Gray
        Write-Host "   State: $($vm.provisioningState)" -ForegroundColor Gray
        Write-Host "   OS: Ubuntu Server 22.04 LTS" -ForegroundColor Gray
        
        # Get power state
        $powerState = az vm get-instance-view --name "vm-jenkins-dev" --resource-group "rg-vr-campus-viewer-dev" --query "instanceView.statuses[?starts_with(code, 'PowerState/')].displayStatus" -o tsv
        Write-Host "   Power State: $powerState" -ForegroundColor Gray
        
        $TestResults += @{Test="Jenkins VM"; Status="PASS"; Details=$powerState}
    }
} catch {
    Write-Host "❌ Jenkins VM not found" -ForegroundColor Red
    $TestResults += @{Test="Jenkins VM"; Status="FAIL"; Details="Not found"}
}

# ===================================================================
# Test 8: Jenkins Public IP
# ===================================================================
Write-Host "`n[8/10] Testing Jenkins Public IP..." -ForegroundColor Yellow
try {
    $pip = az network public-ip show --name "pip-jenkins-dev" --resource-group "rg-vr-campus-viewer-dev" | ConvertFrom-Json
    if ($pip) {
        Write-Host "✅ Jenkins Public IP exists: $($pip.ipAddress)" -ForegroundColor Green
        Write-Host "   Allocation: $($pip.publicIPAllocationMethod)" -ForegroundColor Gray
        Write-Host "   SKU: $($pip.sku.name)" -ForegroundColor Gray
        $TestResults += @{Test="Jenkins Public IP"; Status="PASS"; Details=$pip.ipAddress}
    }
} catch {
    Write-Host "❌ Jenkins Public IP not found" -ForegroundColor Red
    $TestResults += @{Test="Jenkins Public IP"; Status="FAIL"; Details="Not found"}
}

# ===================================================================
# Test 9: Jenkins UI Accessibility
# ===================================================================
Write-Host "`n[9/10] Testing Jenkins UI Accessibility..." -ForegroundColor Yellow
try {
    $jenkinsResponse = Invoke-WebRequest -Uri "http://13.70.38.89:8080" -UseBasicParsing -TimeoutSec 10
    Write-Host "⚠️  Jenkins returned HTTP $($jenkinsResponse.StatusCode) (Authentication required)" -ForegroundColor Yellow
    $TestResults += @{Test="Jenkins UI"; Status="PASS"; Details="Accessible (Auth required)"}
} catch {
    if ($_.Exception.Message -like "*403*") {
        Write-Host "✅ Jenkins is running (HTTP 403 - Authentication required)" -ForegroundColor Green
        Write-Host "   URL: http://13.70.38.89:8080" -ForegroundColor Gray
        $TestResults += @{Test="Jenkins UI"; Status="PASS"; Details="Running (403)"}
    } elseif ($_.Exception.Message -like "*Connection refused*") {
        Write-Host "❌ Jenkins is not accessible (Connection refused)" -ForegroundColor Red
        $TestResults += @{Test="Jenkins UI"; Status="FAIL"; Details="Connection refused"}
    } else {
        Write-Host "⚠️  Jenkins status unclear: $($_.Exception.Message)" -ForegroundColor Yellow
        $TestResults += @{Test="Jenkins UI"; Status="WARN"; Details=$_.Exception.Message}
    }
}

# ===================================================================
# Test 10: Local Files Verification
# ===================================================================
Write-Host "`n[10/10] Testing Local Files..." -ForegroundColor Yellow
$requiredFiles = @(
    "Dockerfile",
    "index.html",
    "nginx.conf",
    "Jenkinsfile",
    "main.tf",
    "terraform.tfvars"
)

$missingFiles = @()
foreach ($file in $requiredFiles) {
    if (Test-Path $file) {
        Write-Host "   ✅ $file" -ForegroundColor Green
    } else {
        Write-Host "   ❌ $file (missing)" -ForegroundColor Red
        $missingFiles += $file
    }
}

if ($missingFiles.Count -eq 0) {
    Write-Host "✅ All required files present" -ForegroundColor Green
    $TestResults += @{Test="Local Files"; Status="PASS"; Details="All present"}
} else {
    Write-Host "❌ Missing files: $($missingFiles -join ', ')" -ForegroundColor Red
    $TestResults += @{Test="Local Files"; Status="FAIL"; Details="$($missingFiles.Count) missing"}
}

# ===================================================================
# Test Summary
# ===================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   TEST SUMMARY" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

$passCount = ($TestResults | Where-Object {$_.Status -eq "PASS"}).Count
$failCount = ($TestResults | Where-Object {$_.Status -eq "FAIL"}).Count
$warnCount = ($TestResults | Where-Object {$_.Status -eq "WARN"}).Count
$totalCount = $TestResults.Count

foreach ($result in $TestResults) {
    $color = switch ($result.Status) {
        "PASS" { "Green" }
        "FAIL" { "Red" }
        "WARN" { "Yellow" }
    }
    Write-Host "$($result.Test.PadRight(25)) [$($result.Status)]" -ForegroundColor $color -NoNewline
    Write-Host " - $($result.Details)" -ForegroundColor Gray
}

Write-Host "`n----------------------------------------" -ForegroundColor Cyan
Write-Host "Total Tests: $totalCount" -ForegroundColor White
Write-Host "Passed:      $passCount" -ForegroundColor Green
Write-Host "Failed:      $failCount" -ForegroundColor Red
Write-Host "Warnings:    $warnCount" -ForegroundColor Yellow
Write-Host "----------------------------------------" -ForegroundColor Cyan

$successRate = [math]::Round(($passCount / $totalCount) * 100, 2)
Write-Host "`nSuccess Rate: $successRate%" -ForegroundColor $(if ($successRate -ge 80) {"Green"} elseif ($successRate -ge 50) {"Yellow"} else {"Red"})

# ===================================================================
# Deployment URLs
# ===================================================================
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   DEPLOYMENT INFORMATION" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Application URL:" -ForegroundColor Yellow
Write-Host "  https://app-vr-campus-viewer-dev.azurewebsites.net" -ForegroundColor Cyan

Write-Host "`nJenkins URL:" -ForegroundColor Yellow
Write-Host "  http://13.70.38.89:8080" -ForegroundColor Cyan
Write-Host "  Initial Admin Password: c7057373d57c417eac02e41f051d7756" -ForegroundColor Gray

Write-Host "`nAzure Portal Resource Group:" -ForegroundColor Yellow
Write-Host "  https://portal.azure.com/#resource/subscriptions/3b193060-7732-4b0d-a8d5-399332a729f0/resourceGroups/rg-vr-campus-viewer-dev/overview" -ForegroundColor Cyan

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "   TEST COMPLETED" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

if ($failCount -eq 0) {
    Write-Host "🎉 All critical tests passed! Deployment is healthy." -ForegroundColor Green
    exit 0
} else {
    Write-Host "⚠️  Some tests failed. Please review the failures above." -ForegroundColor Yellow
    exit 1
}

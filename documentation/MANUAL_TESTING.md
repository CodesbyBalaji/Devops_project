# 🧪 Manual Testing Guide - VR Campus Viewer

Quick reference for testing the deployment manually without automation.

---

## 🌐 Web Application Testing

### Test 1: Basic Accessibility
```bash
# Windows PowerShell
Invoke-WebRequest -Uri "https://app-vr-campus-viewer-dev.azurewebsites.net" -UseBasicParsing

# Expected: HTTP 200 OK
```

### Test 2: Open in Browser
1. Open browser
2. Navigate to: `https://app-vr-campus-viewer-dev.azurewebsites.net`
3. **Expected Results**:
   - VR scene loads
   - 3D campus model appears
   - Movement controls work
   - Audio plays on movement (if enabled)

### Test 3: Check Browser Console
1. Press `F12` to open developer tools
2. Go to Console tab
3. **Expected**: No red errors
4. **Acceptable**: Info/warning messages about WebXR

---

## 🔧 Jenkins Testing

### Test 1: Access Jenkins UI
```bash
# Open in browser:
http://13.70.38.89:8080

# Expected: Jenkins login page or setup wizard
```

### Test 2: Initial Setup (First Time Only)
1. Enter initial admin password: `c7057373d57c417eac02e41f051d7756`
2. Click "Continue"
3. Choose "Install suggested plugins"
4. Create admin user
5. Complete setup wizard

### Test 3: SSH to Jenkins VM
```bash
# Windows PowerShell
ssh -i C:\Users\Development\.ssh\jenkins_azure_key azureuser@13.70.38.89

# Once connected, check services:
sudo systemctl status jenkins
sudo systemctl status docker
```

### Test 4: Verify Jenkins Configuration
```bash
# SSH to Jenkins VM first, then:
cat /var/lib/jenkins/azure-credentials/config.txt

# Expected: Azure credentials file exists
```

---

## 🐳 Docker & ACR Testing

### Test 1: Login to ACR
```bash
# Windows PowerShell
az acr login --name acrvrcampusviewerdev

# Expected: "Login Succeeded"
```

### Test 2: List Images in ACR
```bash
az acr repository list --name acrvrcampusviewerdev
az acr repository show-tags --name acrvrcampusviewerdev --repository vr-campus-viewer

# Expected: Multiple tags (2, 3, 4, 5, latest, v1)
```

### Test 3: Pull and Test Image Locally (Optional)
```bash
# Requires Docker Desktop running
docker pull acrvrcampusviewerdev.azurecr.io/vr-campus-viewer:latest
docker run -d -p 8080:80 acrvrcampusviewerdev.azurecr.io/vr-campus-viewer:latest

# Open browser: http://localhost:8080
# Expected: VR application loads

# Cleanup
docker stop $(docker ps -q)
```

---

## ☁️ Azure Resources Testing

### Test 1: Check All Resources
```bash
az resource list --resource-group rg-vr-campus-viewer-dev --output table

# Expected: 9 resources listed
```

### Test 2: Check Web App Status
```bash
az webapp show \
  --name app-vr-campus-viewer-dev \
  --resource-group rg-vr-campus-viewer-dev \
  --query "{Name:name, State:state, URL:defaultHostName}" \
  --output table

# Expected: State = Running
```

### Test 3: Check Web App Logs
```bash
az webapp log tail \
  --name app-vr-campus-viewer-dev \
  --resource-group rg-vr-campus-viewer-dev

# Expected: Container logs stream (Ctrl+C to stop)
```

### Test 4: Check VM Status
```bash
az vm show \
  --name vm-jenkins-dev \
  --resource-group rg-vr-campus-viewer-dev \
  --query "{Name:name, State:provisioningState, PowerState:instanceView.statuses[1].displayStatus}" \
  --output table

# Expected: State = Succeeded, PowerState = VM running
```

---

## 🔄 CI/CD Pipeline Testing

### Test 1: Manual Pipeline Trigger (In Jenkins UI)
1. Log into Jenkins: `http://13.70.38.89:8080`
2. Create new item → Pipeline
3. Configure pipeline to use `Jenkinsfile` from Git
4. Save and click "Build Now"
5. Watch console output

**Expected Pipeline Stages**:
1. ✅ Checkout
2. ✅ Verify Prerequisites
3. ✅ Build Docker Image
4. ✅ Test Docker Image
5. ✅ Push to ACR
6. ✅ Deploy to Azure App Service
7. ✅ Health Check
8. ✅ Cleanup

### Test 2: Verify Jenkins Credentials (In Jenkins UI)
1. Go to: Manage Jenkins → Manage Credentials
2. Check for these credentials:
   - `azure-service-principal`
   - `acr-login-server`
   - `acr-username`
   - `acr-password`
   - `azure-resource-group`
   - `azure-webapp-name`

---

## 🚀 Deployment Testing

### Test 1: Deploy New Version Manually
```bash
# 1. Build new image
cd "c:\Users\Development\Documents\Personal Projects\3rd Internal\Devops_project"
docker build -t vr-campus-viewer:test .

# 2. Tag for ACR
docker tag vr-campus-viewer:test acrvrcampusviewerdev.azurecr.io/vr-campus-viewer:test

# 3. Login to ACR
az acr login --name acrvrcampusviewerdev

# 4. Push to ACR
docker push acrvrcampusviewerdev.azurecr.io/vr-campus-viewer:test

# 5. Update Web App
az webapp config container set \
  --name app-vr-campus-viewer-dev \
  --resource-group rg-vr-campus-viewer-dev \
  --docker-custom-image-name acrvrcampusviewerdev.azurecr.io/vr-campus-viewer:test

# 6. Restart Web App
az webapp restart \
  --name app-vr-campus-viewer-dev \
  --resource-group rg-vr-campus-viewer-dev

# 7. Wait 30 seconds, then test
Start-Sleep -Seconds 30
Invoke-WebRequest -Uri "https://app-vr-campus-viewer-dev.azurewebsites.net" -UseBasicParsing
```

---

## 🔍 Troubleshooting Tests

### Test 1: Check Web App is Pulling Correct Image
```bash
az webapp config show \
  --name app-vr-campus-viewer-dev \
  --resource-group rg-vr-campus-viewer-dev \
  --query "linuxFxVersion"

# Expected: DOCKER|acrvrcampusviewerdev.azurecr.io/vr-campus-viewer:<version>
```

### Test 2: Check Web App Environment Variables
```bash
az webapp config appsettings list \
  --name app-vr-campus-viewer-dev \
  --resource-group rg-vr-campus-viewer-dev \
  --output table

# Expected: Docker registry settings present
```

### Test 3: Test Jenkins VM Connectivity
```bash
# Test SSH port
Test-NetConnection -ComputerName 13.70.38.89 -Port 22

# Test Jenkins port
Test-NetConnection -ComputerName 13.70.38.89 -Port 8080

# Expected: Both TcpTestSucceeded = True
```

### Test 4: Check NSG Rules
```bash
az network nsg rule list \
  --nsg-name nsg-jenkins-dev \
  --resource-group rg-vr-campus-viewer-dev \
  --output table

# Expected: Rules for SSH (22), Jenkins (8080), HTTPS (443)
```

---

## 📊 Performance Testing

### Test 1: Application Load Time
```bash
# Measure response time
Measure-Command {
  Invoke-WebRequest -Uri "https://app-vr-campus-viewer-dev.azurewebsites.net" -UseBasicParsing
}

# Expected: < 5 seconds (first load), < 2 seconds (cached)
```

### Test 2: Check Resource Usage
```bash
# VM metrics
az vm list-usage \
  --location eastasia \
  --output table

# App Service metrics
az monitor metrics list \
  --resource /subscriptions/3b193060-7732-4b0d-a8d5-399332a729f0/resourceGroups/rg-vr-campus-viewer-dev/providers/Microsoft.Web/sites/app-vr-campus-viewer-dev \
  --metric "CpuPercentage" \
  --output table
```

---

## 🎯 Acceptance Criteria Checklist

### Application
- [ ] Web app loads without errors
- [ ] VR scene renders correctly
- [ ] 3D model is visible
- [ ] Movement controls work
- [ ] Audio plays (if enabled)
- [ ] No console errors in browser

### Infrastructure
- [ ] All Azure resources are running
- [ ] Web app returns HTTP 200
- [ ] ACR contains images
- [ ] Jenkins VM is accessible
- [ ] Network connectivity is working

### CI/CD
- [ ] Jenkins UI is accessible
- [ ] Jenkins credentials configured
- [ ] Pipeline can be triggered
- [ ] Pipeline completes successfully
- [ ] Deployment updates web app

### Security
- [ ] HTTPS enabled on web app
- [ ] Jenkins requires authentication
- [ ] ACR admin credentials work
- [ ] SSH keys configured for VM

---

## 🔗 Quick Links

| Resource | URL |
|----------|-----|
| **Application** | https://app-vr-campus-viewer-dev.azurewebsites.net |
| **Jenkins** | http://13.70.38.89:8080 |
| **Azure Portal** | https://portal.azure.com |
| **GitHub Repo** | https://github.com/CodesbyBalaji/Devops_project |
| **ACR** | acrvrcampusviewerdev.azurecr.io |

---

## 🆘 Common Commands

```powershell
# Quick status check
az resource list --resource-group rg-vr-campus-viewer-dev --query "[].{Name:name,Type:type,State:properties.provisioningState}" -o table

# Restart everything
az webapp restart --name app-vr-campus-viewer-dev --resource-group rg-vr-campus-viewer-dev
az vm restart --name vm-jenkins-dev --resource-group rg-vr-campus-viewer-dev

# View logs
az webapp log tail --name app-vr-campus-viewer-dev --resource-group rg-vr-campus-viewer-dev

# Test application
Invoke-WebRequest -Uri "https://app-vr-campus-viewer-dev.azurewebsites.net" -UseBasicParsing
```

---

## ⚠️ What NOT to Test (Per Instructions)

❌ **GitHub Webhook** - Explicitly excluded from testing:
- Not configured in GitHub
- Not verified in Jenkins
- Will be tested separately later

---

**Last Updated**: October 30, 2025  
**Status**: All manual tests available and documented

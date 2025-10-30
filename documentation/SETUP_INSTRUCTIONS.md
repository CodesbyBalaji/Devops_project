# 🚀 Final Setup Steps - GitHub Webhook & First Build

## Current Status: 90% Complete ✅

Everything is automated and ready! You just need to complete 2 final steps.

---

## ⚠️ Important: Repository Access

Since you're seeing a 404 on the settings page, this means:
- Either the repository is private and you're not logged into GitHub
- Or you need to be added as a collaborator with admin rights

### Solution Options:

### **Option A: If this is YOUR repository:**
1. Make sure you're logged into GitHub in your browser
2. Try this link: https://github.com/CodesbyBalaji/Devops_project/settings
3. If you see the settings page, continue to Step 1 below

### **Option B: If someone else owns the repository:**
Ask the repository owner to:
1. Go to: https://github.com/CodesbyBalaji/Devops_project/settings/hooks
2. Click "Add webhook"
3. Use these settings:
   - **Payload URL**: `http://13.70.38.89:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Secret**: (leave blank)
   - **Events**: Just the push event
   - **Active**: ✓ (checked)
4. Click "Add webhook"

### **Option C: Skip webhook for now (Test manually first)**
You can skip the webhook and test the pipeline manually first. The webhook just automates triggering builds on git push. You can always add it later!

---

## 📋 Step 1: Add GitHub Webhook (if you have access)

### Method 1: Through GitHub Web UI

1. **Open GitHub Settings:**
   - Log into GitHub in your browser
   - Navigate to: https://github.com/CodesbyBalaji/Devops_project/settings/hooks
   - Click **"Add webhook"** (green button)

2. **Configure the webhook:**
   ```
   Payload URL: http://13.70.38.89:8080/github-webhook/
   Content type: application/json
   Secret: (leave blank)
   SSL verification: (leave as is)
   Which events: Just the push event ✓
   Active: ✓ (checked)
   ```

3. **Save:**
   - Click "Add webhook" button
   - GitHub will send a test ping
   - You should see a green ✓ checkmark

### Method 2: Using curl (if you have a GitHub token)

If you have a GitHub Personal Access Token, run this command:

```powershell
# Replace YOUR_GITHUB_TOKEN with your actual token
$token = "YOUR_GITHUB_TOKEN"
$body = @{
    name = "web"
    active = $true
    events = @("push")
    config = @{
        url = "http://13.70.38.89:8080/github-webhook/"
        content_type = "json"
        insecure_ssl = "0"
    }
} | ConvertTo-Json

Invoke-RestMethod -Uri "https://api.github.com/repos/CodesbyBalaji/Devops_project/hooks" `
    -Method Post `
    -Headers @{Authorization = "token $token"} `
    -Body $body `
    -ContentType "application/json"
```

---

## 📋 Step 2: Trigger First Build (3 minutes)

### Open Jenkins

1. **Open your browser and go to:**
   ```
   http://13.70.38.89:8080
   ```

2. **Login:**
   - Username: `admin`
   - Password: `admin123`

### Start the Build

3. **Navigate to the pipeline:**
   - You'll see "vr-campus-viewer-pipeline" on the dashboard
   - Click on "vr-campus-viewer-pipeline"

4. **Trigger the build:**
   - Click **"Build Now"** in the left sidebar
   - The build will appear under "Build History"

5. **Monitor the build:**
   - Click on the build number (e.g., "#1")
   - Click **"Console Output"**
   - Watch the build progress in real-time

### Expected Build Stages (Total ~5-10 minutes)

You should see these 7 stages execute:

```
✓ Stage 1: Checkout
  └─ Cloning repository from GitHub

✓ Stage 2: Verify Prerequisites  
  └─ Checking Docker, Azure CLI, credentials

✓ Stage 3: Build Docker Image
  └─ Building vr-campus-viewer:latest
  
✓ Stage 4: Test Docker Image
  └─ Running container tests

✓ Stage 5: Push to ACR
  └─ Pushing image to Azure Container Registry
  
✓ Stage 6: Deploy to Azure
  └─ Updating Azure Web App

✓ Stage 7: Health Check
  └─ Verifying deployment success
```

---

## ✅ Success Indicators

### During Build:
- Each stage shows `[Pipeline]` prefix
- Green `SUCCESS` messages after each stage
- No red `ERROR` or `FAILED` messages

### After Build Completes:
1. **Jenkins shows:**
   - Build status: ✅ Success (blue ball)
   - "Finished: SUCCESS" at the bottom of console

2. **Website is updated:**
   - Open: https://app-vr-campus-viewer-dev.azurewebsites.net
   - Should show your latest code changes

3. **ACR has new image:**
   ```powershell
   az acr repository show-tags --name acrvrcampusviewerdev --repository vr-campus-viewer
   ```
   Should show a new tag with timestamp

---

## 🔍 Troubleshooting

### Build Fails on Stage 2 (Verify Prerequisites)?
**Problem:** Missing credentials or tools

**Solution:**
```powershell
# SSH into Jenkins VM
ssh -i "$HOME\.ssh\jenkins_azure_key" azureuser@13.70.38.89

# Check Docker
docker --version

# Check Azure CLI
az --version

# Check credentials in Jenkins
curl -u admin:admin123 http://localhost:8080/credentials/store/system/domain/_/api/json
```

### Build Fails on Stage 3 (Build Docker Image)?
**Problem:** Dockerfile missing or syntax error

**Solution:** Check that Dockerfile exists in your repository root

### Build Fails on Stage 5 (Push to ACR)?
**Problem:** ACR credentials incorrect

**Solution:**
```powershell
# Test ACR login manually
az acr login --name acrvrcampusviewerdev
```

### Build Fails on Stage 6 (Deploy to Azure)?
**Problem:** Azure CLI authentication or web app access

**Solution:** Check service principal has Contributor role on resource group

---

## 🎉 What Happens After First Successful Build?

Once the first build succeeds:

1. **Automated CI/CD is LIVE! 🚀**
   - Every `git push` to main branch triggers automatic build
   - Webhook notifies Jenkins → Jenkins builds → Deploys to Azure
   - Complete automation from code commit to production

2. **Test it:**
   ```bash
   # Make a small change
   echo "<!-- Updated at $(date) -->" >> index.html
   
   # Commit and push
   git add .
   git commit -m "Test CI/CD automation"
   git push origin main
   
   # Watch Jenkins automatically start building!
   ```

3. **Monitor builds:**
   - Jenkins: http://13.70.38.89:8080
   - Website: https://app-vr-campus-viewer-dev.azurewebsites.net

---

## 📊 Current Infrastructure

```
┌─────────────────────────────────────────────────────────────┐
│                     YOUR CI/CD PIPELINE                      │
└─────────────────────────────────────────────────────────────┘

GitHub Repository (CodesbyBalaji/Devops_project)
    │
    │ (1) Git Push
    ↓
GitHub Webhook → Jenkins (13.70.38.89:8080)
                    │
                    │ (2) Clone Code
                    ↓
                 Docker Build
                    │
                    │ (3) Push Image
                    ↓
        Azure Container Registry (acrvrcampusviewerdev.azurecr.io)
                    │
                    │ (4) Deploy
                    ↓
        Azure Web App (app-vr-campus-viewer-dev)
                    │
                    │ (5) Serve
                    ↓
        Live Website (https://app-vr-campus-viewer-dev.azurewebsites.net)
```

---

## 🆘 Need Help?

If you encounter any issues:

1. **Check Jenkins logs:**
   ```powershell
   ssh -i "$HOME\.ssh\jenkins_azure_key" azureuser@13.70.38.89
   sudo journalctl -u jenkins -f
   ```

2. **Check build console output in Jenkins UI**
   - The console output shows exactly what's happening

3. **Verify all credentials exist:**
   ```powershell
   # SSH to Jenkins
   ssh -i "$HOME\.ssh\jenkins_azure_key" azureuser@13.70.38.89
   
   # Check credentials
   curl -u admin:admin123 http://localhost:8080/credentials/store/system/domain/_/api/json | python3 -c "import sys,json; data=json.load(sys.stdin); print(f'Total: {len(data[\"credentials\"])}')"
   ```

---

## 📝 Quick Reference

| Component | URL/Location | Credentials |
|-----------|-------------|-------------|
| **Website** | https://app-vr-campus-viewer-dev.azurewebsites.net | N/A |
| **Jenkins** | http://13.70.38.89:8080 | admin / admin123 |
| **GitHub** | https://github.com/CodesbyBalaji/Devops_project | Your GitHub account |
| **Azure Portal** | https://portal.azure.com | Your Azure account |
| **ACR** | acrvrcampusviewerdev.azurecr.io | (in Jenkins credentials) |

---

## 🎯 Summary

**What's Done (90%):**
- ✅ Infrastructure deployed
- ✅ Jenkins configured
- ✅ Credentials added
- ✅ Pipeline job created
- ✅ Website live

**What's Left (10%):**
- ⏳ Add GitHub webhook (or skip for manual triggering)
- ⏳ Run first build
- ⏳ Test automation

**Time Required:** 5-10 minutes total

---

Good luck! 🚀

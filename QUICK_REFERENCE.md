# CI/CD Setup - Quick Reference Guide
**Date**: October 30, 2025  
**Status**: ✅ OPERATIONAL

---

## 🌐 YOUR LIVE WEBSITE

**URL**: https://app-vr-campus-viewer-dev.azurewebsites.net  
**Status**: ✅ LIVE (HTTP 200)  
**Container**: acrvrcampusviewerdev.azurecr.io/vr-campus-viewer:latest

---

## 🔐 ACCESS CREDENTIALS

### Jenkins Dashboard
- **URL**: http://13.70.38.89:8080
- **Username**: `admin`
- **Password**: `admin123`
- **Pipeline Job**: http://13.70.38.89:8080/job/vr-campus-viewer-pipeline/

### SSH Access to Jenkins VM
```bash
ssh -i C:\Users\Development\.ssh\jenkins_azure_key azureuser@13.70.38.89
```

### All Other Credentials
See: `JENKINS_CREDENTIALS.txt` (local file, not in Git)

---

## ✅ WHAT'S DONE (Automated via CLI)

- [x] **Website Deployed**: Updated from nginx:alpine to vr-campus-viewer:latest
- [x] **ACR Credentials**: Configured on Azure Web App
- [x] **Jenkins Credentials**: 7 credentials configured via Groovy script
- [x] **Pipeline Job**: `vr-campus-viewer-pipeline` created and configured
- [x] **Job Configuration**: Points to GitHub repo + Jenkinsfile
- [x] **GitHub Trigger**: Enabled in job configuration
- [x] **Plugins**: Installation initiated (completing automatically)

---

## 📋 REMAINING TASKS (5-10 minutes total)

### 1. Add GitHub Webhook (2 minutes)

**Manual Method** (Recommended):
1. Go to: https://github.com/CodesbyBalaji/Devops_project/settings/hooks
2. Click "Add webhook"
3. Enter these details:
   - **Payload URL**: `http://13.70.38.89:8080/github-webhook/`
   - **Content type**: `application/json`
   - **Events**: Select "Just the push event"
4. Click "Add webhook"

**API Method** (if you have GitHub token):
```bash
curl -X POST \
  -H "Authorization: token YOUR_GITHUB_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/repos/CodesbyBalaji/Devops_project/hooks \
  -d '{
    "name": "web",
    "active": true,
    "events": ["push"],
    "config": {
      "url": "http://13.70.38.89:8080/github-webhook/",
      "content_type": "json",
      "insecure_ssl": "1"
    }
  }'
```

### 2. Verify Jenkins Plugins (1 minute)

1. Login to Jenkins: http://13.70.38.89:8080
2. Go to: Manage Jenkins → Manage Plugins → Installed
3. Verify these plugins are installed and active:
   - ✓ Git
   - ✓ GitHub
   - ✓ Pipeline (workflow-aggregator)
   - ✓ Docker Pipeline (docker-workflow)
   - ✓ Credentials Binding

If any are missing:
- Go to: Available tab
- Search for the plugin
- Check the box and click "Install without restart"

### 3. Trigger First Build (5 minutes)

1. Login to Jenkins: http://13.70.38.89:8080
2. Click on: `vr-campus-viewer-pipeline`
3. Click: "Build Now" (left sidebar)
4. Watch the build progress in real-time
5. Click on build #1 → "Console Output" to see details

**Expected Build Stages** (3-5 minutes total):
1. ✓ Checkout (~10s) - Clone from GitHub
2. ✓ Verify Prerequisites (~5s) - Check files
3. ✓ Build Docker Image (~60s) - Create container
4. ✓ Test Docker Image (~15s) - Verify it works
5. ✓ Push to ACR (~30s) - Upload to registry
6. ✓ Deploy to Azure (~45s) - Update Web App
7. ✓ Health Check (~30s) - Verify deployment

**If Build Fails**: Check console output for errors, most common issues:
- Missing plugins → Install from Plugin Manager
- Credential issues → Verify in Manage Credentials
- Docker permissions → May need to add jenkins user to docker group

---

## 🚀 HOW TO USE CI/CD PIPELINE

### Automatic Deployment (After webhook setup)

1. Make changes to your code locally
2. Commit changes: `git add . && git commit -m "Your message"`
3. Push to GitHub: `git push origin main`
4. **Jenkins automatically**:
   - Detects the push via webhook
   - Triggers build
   - Builds Docker image
   - Tests the image
   - Pushes to ACR
   - Deploys to Azure
   - Verifies deployment
5. Your website updates automatically! 🎉

### Manual Deployment

1. Go to: http://13.70.38.89:8080/job/vr-campus-viewer-pipeline/
2. Click "Build Now"
3. Monitor progress
4. Website updates when build completes

---

## 📊 MONITORING & LOGS

### View Build History
- Jenkins: http://13.70.38.89:8080/job/vr-campus-viewer-pipeline/
- Each build shows: Number, Status, Duration, Changes

### View Build Logs
- Click any build number
- Click "Console Output"
- See real-time or historical logs

### View Website Logs
```bash
az webapp log tail \
  --name app-vr-campus-viewer-dev \
  --resource-group rg-vr-campus-viewer-dev
```

### View Container Registry
```bash
# List images
az acr repository list --name acrvrcampusviewerdev --output table

# List tags
az acr repository show-tags \
  --name acrvrcampusviewerdev \
  --repository vr-campus-viewer \
  --output table
```

---

## 🔧 TROUBLESHOOTING

### Website Not Loading
```bash
# Check web app status
az webapp show \
  --name app-vr-campus-viewer-dev \
  --resource-group rg-vr-campus-viewer-dev \
  --query state

# Restart web app
az webapp restart \
  --name app-vr-campus-viewer-dev \
  --resource-group rg-vr-campus-viewer-dev
```

### Jenkins Not Accessible
```bash
# SSH to Jenkins VM
ssh -i C:\Users\Development\.ssh\jenkins_azure_key azureuser@13.70.38.89

# Check Jenkins status
sudo systemctl status jenkins

# Restart Jenkins
sudo systemctl restart jenkins
```

### Pipeline Build Fails
1. Check Console Output for specific error
2. Common fixes:
   - Verify credentials in Manage Jenkins → Manage Credentials
   - Install missing plugins
   - Check Docker is running: `sudo systemctl status docker`
   - Verify Azure CLI: `az --version`

### Webhook Not Triggering
1. Go to: https://github.com/CodesbyBalaji/Devops_project/settings/hooks
2. Click on the webhook
3. Scroll to "Recent Deliveries"
4. Check if requests are being sent and responses received
5. Response should be HTTP 200

---

## 📈 WHAT'S NEXT

### Enhancements You Can Add

1. **Automated Testing**
   - Add unit tests to Dockerfile
   - Include test stage in Jenkinsfile
   - Fail build if tests don't pass

2. **Environment Variables**
   - Add environment-specific configs
   - Use different ACR tags for dev/staging/prod
   - Configure via Azure App Settings

3. **Notifications**
   - Add Slack/Teams/Email notifications
   - Install notification plugins in Jenkins
   - Configure in Pipeline post actions

4. **Blue-Green Deployment**
   - Create staging slot in Azure Web App
   - Deploy to staging first
   - Swap slots for zero-downtime

5. **Monitoring & Alerts**
   - Setup Azure Application Insights
   - Configure health check endpoints
   - Alert on deployment failures

---

## 📞 QUICK COMMANDS

### Redeploy Current Website
```bash
az webapp restart \
  --name app-vr-campus-viewer-dev \
  --resource-group rg-vr-campus-viewer-dev
```

### Manually Trigger Jenkins Build
```bash
ssh -i C:\Users\Development\.ssh\jenkins_azure_key azureuser@13.70.38.89
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 \
  -auth admin:admin123 \
  build vr-campus-viewer-pipeline -s -v
```

### View Latest ACR Image
```bash
az acr repository show-tags \
  --name acrvrcampusviewerdev \
  --repository vr-campus-viewer \
  --orderby time_desc \
  --output table \
  | head -5
```

### Check Jenkins Credentials
```bash
ssh -i C:\Users\Development\.ssh\jenkins_azure_key azureuser@13.70.38.89
curl -s -u admin:admin123 \
  'http://localhost:8080/credentials/store/system/domain/_/api/json' \
  | python3 -m json.tool
```

---

## 🎯 SUCCESS CHECKLIST

- [x] Website is live and accessible
- [x] Jenkins server running
- [x] Jenkins credentials configured
- [x] Pipeline job created
- [ ] GitHub webhook added (manual step)
- [ ] First build run successfully (manual trigger)
- [ ] Automatic deployment tested (push code change)

---

## 📚 DOCUMENTATION FILES

- `AUTOMATION_PLAN.md` - Complete automation strategy and plan
- `DEPLOYMENT_STATUS.md` - Infrastructure deployment details
- `JENKINS_SETUP.md` - Jenkins setup guide
- `JENKINS_CREDENTIALS.txt` - All credentials (LOCAL ONLY, NOT IN GIT)
- `QUICK_REFERENCE.md` - This file

---

**Last Updated**: October 30, 2025  
**Status**: Infrastructure Operational, Webhook & First Build Pending

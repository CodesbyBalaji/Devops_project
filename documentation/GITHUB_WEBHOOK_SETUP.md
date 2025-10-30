# 🔗 GitHub Webhook Configuration Guide

Complete step-by-step guide for configuring GitHub webhook to trigger Jenkins pipeline.

---

## 📋 Prerequisites

Before configuring the webhook, ensure:
- ✅ Jenkins is running: http://13.70.38.89:8080
- ✅ Jenkins has GitHub plugin installed
- ✅ Repository exists: https://github.com/CodesbyBalaji/Devops_project

---

## 🔧 Step-by-Step Configuration

### Step 1: Access Repository Settings

1. Go to your GitHub repository: https://github.com/CodesbyBalaji/Devops_project
2. Click **Settings** (top right of repository page)
3. In the left sidebar, click **Webhooks**
4. Click **Add webhook** button (green button on right)

---

### Step 2: Configure Webhook Settings

#### **Payload URL** ⭐ REQUIRED
```
http://13.70.38.89:8080/github-webhook/
```
**Important Notes:**
- ⚠️ Must end with `/` (slash)
- ⚠️ Must be `http://` (not `https://` - Jenkins doesn't have SSL)
- ⚠️ Port `:8080` is required
- ⚠️ Path must be `/github-webhook/`

#### **Content type** ⭐ SELECT THIS
```
application/json
```
**Options available:**
- ❌ application/x-www-form-urlencoded (Don't use)
- ✅ **application/json** (Use this one!)

**Why JSON?** Jenkins GitHub plugin expects JSON format for webhook payloads.

---

### Step 3: Secret (Optional but Recommended)

#### **Secret** 🔐 OPTIONAL
```
Leave blank for now
```

**For production, you should:**
1. Generate a random secret token
2. Add it here in GitHub
3. Configure the same secret in Jenkins webhook settings

**Example secret generation (PowerShell):**
```powershell
-join ((48..57) + (65..90) + (97..122) | Get-Random -Count 32 | ForEach-Object {[char]$_})
```

---

### Step 4: Which events would you like to trigger this webhook?

⭐ **SELECT THIS OPTION:**
```
○ Just the push event (RECOMMENDED)
```

**Available Options:**

#### Option 1: Just the push event ✅ RECOMMENDED
- **Select:** ✅ **Use this one**
- **Triggers when:** Code is pushed to any branch
- **Best for:** Continuous Integration/Deployment
- **Frequency:** Every git push

#### Option 2: Send me everything ❌ NOT RECOMMENDED
- **Select:** ❌ Don't use
- **Triggers when:** Any GitHub event (issues, PRs, comments, etc.)
- **Problem:** Too many unnecessary builds
- **Use case:** Advanced monitoring only

#### Option 3: Let me select individual events ⚠️ ADVANCED
- **Select:** Only if you need specific events
- **Common selections for CI/CD:**
  - ✅ Pushes (code commits)
  - ✅ Pull requests (for PR validation)
  - ❌ Issues (not needed for deployment)
  - ❌ Issue comments (not needed)
  - ❌ Releases (optional)

**For this project, select: Just the push event**

---

### Step 5: Active

#### **Active** ⭐ REQUIRED
```
✅ Active (checkbox must be checked)
```

**What this means:**
- ✅ Checked = Webhook is enabled and will trigger
- ❌ Unchecked = Webhook is disabled (saved but won't trigger)

**Always keep this checked!**

---

## 📝 Complete Configuration Summary

Here's what your webhook configuration should look like:

```
┌─────────────────────────────────────────────────┐
│ Add webhook                                     │
├─────────────────────────────────────────────────┤
│                                                 │
│ Payload URL *                                   │
│ http://13.70.38.89:8080/github-webhook/        │
│                                                 │
│ Content type *                                  │
│ [application/json ▼]                            │
│                                                 │
│ Secret                                          │
│ [                                    ]          │
│                                                 │
│ Which events would you like to trigger this    │
│ webhook?                                        │
│ ● Just the push event                           │
│ ○ Send me everything                            │
│ ○ Let me select individual events               │
│                                                 │
│ ✅ Active                                       │
│ We will deliver event details when this hook   │
│ is triggered.                                   │
│                                                 │
│        [Add webhook]                            │
└─────────────────────────────────────────────────┘
```

---

## ✅ Quick Checklist

Before clicking "Add webhook", verify:

- [ ] Payload URL: `http://13.70.38.89:8080/github-webhook/`
- [ ] URL ends with `/` (slash)
- [ ] Content type: `application/json`
- [ ] Event trigger: `Just the push event`
- [ ] Active: `✅ Checked`
- [ ] Jenkins is running and accessible

---

## 🧪 Testing the Webhook

### After Adding Webhook

1. **Verify webhook was added:**
   - GitHub will show a green checkmark ✅ or red X ❌
   - Green = successful ping to Jenkins
   - Red = Jenkins not reachable

2. **Check Recent Deliveries:**
   - Click on the webhook in GitHub settings
   - Scroll to "Recent Deliveries"
   - Should see a "ping" event with Response code 200

3. **Test with actual push:**
   ```powershell
   # Make a small change
   echo "# Test webhook" >> README.md
   git add .
   git commit -m "Test webhook trigger"
   git push origin main
   ```

4. **Verify in Jenkins:**
   - Go to Jenkins: http://13.70.38.89:8080
   - Check if build was triggered automatically
   - Look for new build number in your pipeline

---

## 🔍 Troubleshooting

### Webhook shows red X ❌

**Problem:** Jenkins not reachable from GitHub

**Solutions:**
1. **Check Jenkins is running:**
   ```powershell
   Test-NetConnection -ComputerName 13.70.38.89 -Port 8080
   ```

2. **Check Network Security Group:**
   - Port 8080 must be open to internet
   - Check Azure NSG rules allow inbound on 8080

3. **Check Jenkins is responding:**
   - Open browser to http://13.70.38.89:8080
   - Should see Jenkins login page

### Webhook delivers but Jenkins doesn't build

**Problem:** Jenkins not configured to accept webhooks

**Solutions:**
1. **Install GitHub Plugin in Jenkins:**
   - Manage Jenkins → Manage Plugins
   - Install "GitHub Plugin"

2. **Configure Jenkins Job:**
   - Job Configuration → Build Triggers
   - Enable "GitHub hook trigger for GITScm polling"

3. **Check Jenkins logs:**
   ```bash
   # SSH to Jenkins VM
   ssh azureuser@13.70.38.89
   sudo tail -f /var/log/jenkins/jenkins.log
   ```

### Webhook delivers but shows 403 or 404

**Problem:** Wrong URL format

**Solutions:**
- Ensure URL is: `http://13.70.38.89:8080/github-webhook/`
- Must have trailing slash `/`
- Must be `/github-webhook/` not `/github-hook/`

---

## 📊 Webhook Event Payload Example

When GitHub sends a webhook, it looks like this:

```json
{
  "ref": "refs/heads/main",
  "before": "abc123...",
  "after": "def456...",
  "repository": {
    "name": "Devops_project",
    "full_name": "CodesbyBalaji/Devops_project",
    "owner": {
      "name": "CodesbyBalaji"
    }
  },
  "pusher": {
    "name": "CodesbyBalaji",
    "email": "your@email.com"
  },
  "commits": [
    {
      "id": "def456...",
      "message": "Update index.html",
      "timestamp": "2025-10-30T09:00:00Z",
      "author": {
        "name": "Your Name",
        "email": "your@email.com"
      }
    }
  ]
}
```

Jenkins parses this and starts a build.

---

## 🔐 Security Best Practices

### For Production Use:

1. **Add webhook secret:**
   ```
   Generate random token → Add to GitHub → Configure in Jenkins
   ```

2. **Restrict IP access (optional):**
   ```
   Update Azure NSG to allow only GitHub IP ranges
   GitHub webhook IPs: https://api.github.com/meta
   ```

3. **Use HTTPS (future enhancement):**
   ```
   Configure SSL certificate on Jenkins
   Update webhook URL to https://
   ```

4. **Validate payloads:**
   ```
   Jenkins should validate webhook signature
   Configure in Jenkins GitHub plugin settings
   ```

---

## 📋 Configuration Values Reference

| Setting | Value | Required |
|---------|-------|----------|
| **Payload URL** | `http://13.70.38.89:8080/github-webhook/` | ✅ Yes |
| **Content Type** | `application/json` | ✅ Yes |
| **Secret** | (leave blank for now) | ❌ Optional |
| **SSL Verification** | Enable SSL verification | ✅ Yes (default) |
| **Events** | Just the push event | ✅ Yes |
| **Active** | ✅ Checked | ✅ Yes |

---

## 🎯 Expected Behavior

### After webhook is configured:

1. **On git push:**
   - GitHub sends webhook to Jenkins
   - Jenkins receives webhook
   - Jenkins starts pipeline automatically
   - Pipeline runs all stages
   - New Docker image built
   - Image pushed to ACR
   - Web app updated
   - Health check performed

2. **Notification in GitHub:**
   - Commit shows build status (pending/success/failure)
   - Green checkmark ✅ = build succeeded
   - Red X ❌ = build failed

3. **In Jenkins:**
   - Build appears in build history
   - Console output shows git commit that triggered it
   - Build number increments

---

## 📞 Quick Reference

**Webhook URL Format:**
```
http://[JENKINS_IP]:[JENKINS_PORT]/github-webhook/
```

**Your Webhook URL:**
```
http://13.70.38.89:8080/github-webhook/
```

**Test Command:**
```powershell
# Test if webhook URL is reachable
Invoke-WebRequest -Uri "http://13.70.38.89:8080" -UseBasicParsing
```

**GitHub Webhook Documentation:**
https://docs.github.com/en/webhooks

---

## ✅ Final Checklist

Before you finish:

- [ ] Webhook added in GitHub
- [ ] URL is correct with trailing `/`
- [ ] Content type is `application/json`
- [ ] "Just the push event" selected
- [ ] Active checkbox is checked
- [ ] Green checkmark appears in GitHub
- [ ] Test push triggers Jenkins build
- [ ] Build completes successfully

---

**Status**: Ready to configure  
**Difficulty**: Easy  
**Time Required**: 2-3 minutes  
**Risk Level**: Low (can delete and re-add anytime)

---

*Last Updated: October 30, 2025*

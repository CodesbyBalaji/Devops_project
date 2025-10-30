# Fix Jenkins CSRF Protection Issue

## Current Issue
When trying to modify the Jenkins job configuration (specifically to uncheck "Lightweight checkout"), you encounter an error:
```
Oops! A problem occurred while processing the request
Logging ID: 067181e5-475f-4c4c-80fe-c6e7398e05dd
```

## Root Cause
Jenkins CSRF (Cross-Site Request Forgery) protection is interfering with legitimate configuration changes.

## Solution

### Step 1: Disable CSRF Protection Temporarily

1. Go to: http://13.70.38.89:8080/manage
2. Click **"Configure Global Security"**
3. Scroll down to **"CSRF Protection"** section
4. **Uncheck** the box next to "Default Crumb Issuer"
5. Click **"Apply"** button at the bottom
6. Click **"Save"** button

### Step 2: Fix the Job Configuration

1. Go to: http://13.70.38.89:8080/job/vr-campus-viewer-pipeline/configure
2. Scroll down to the **"Pipeline"** section
3. Under "Script Path from SCM" → "Additional Behaviours"
4. Find **"Lightweight checkout"** option
5. **Uncheck** the "Lightweight checkout" box
6. Click **"Save"**

### Step 3: Re-enable CSRF Protection (IMPORTANT!)

1. Go back to: http://13.70.38.89:8080/manage
2. Click **"Configure Global Security"**
3. Scroll down to **"CSRF Protection"** section
4. **Check** the box next to "Default Crumb Issuer"
5. Click **"Apply"**
6. Click **"Save"**

### Step 4: Test Webhook Trigger

1. Make a small change to your code
2. Commit and push to GitHub:
   ```bash
   git add .
   git commit -m "Test webhook after fixing lightweight checkout"
   git push origin main
   ```
3. Check Jenkins: http://13.70.38.89:8080/job/vr-campus-viewer-pipeline/
4. A new build should start automatically with "Started by GitHub push"
5. Check Poll Log: http://13.70.38.89:8080/job/vr-campus-viewer-pipeline/scmPollLog/
   - Should show polling activity and changes detected

## Why This Works

The "Lightweight checkout" option prevents Jenkins from doing a full Git clone, which means:
- SCM polling cannot initialize properly
- Jenkins can't detect changes from webhooks
- The Poll Log shows "Polling has not run yet"

By unchecking this option:
- Jenkins does a full Git clone
- SCM polling can track changes
- Webhooks can trigger builds automatically
- Latest commits are properly checked out

## Security Note

⚠️ **IMPORTANT**: Always re-enable CSRF protection after making configuration changes. CSRF protection is a critical security feature that prevents unauthorized modifications to your Jenkins instance.

## Verification

After completing all steps, verify:
1. ✅ CSRF protection is re-enabled
2. ✅ "Lightweight checkout" is unchecked in job configuration
3. ✅ Test commit triggers automatic build
4. ✅ Build shows "Started by GitHub push" (not "Started by user admin")
5. ✅ Latest commit is checked out in the build
6. ✅ Poll Log shows polling activity

## Troubleshooting

If webhook still doesn't trigger after fixing:
1. Check GitHub webhook deliveries: https://github.com/CodesbyBalaji/Devops_project/settings/hooks
2. Verify payload URL: http://13.70.38.89:8080/github-webhook/
3. Check Jenkins System Log: http://13.70.38.89:8080/log/all
4. Verify "GitHub hook trigger for GITScm polling" is enabled in job config
5. Check firewall rules allow GitHub webhooks (IP ranges: https://api.github.com/meta)

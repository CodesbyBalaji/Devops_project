# Complete CI/CD Automation Plan
**Generated**: October 30, 2025  
**Objective**: Fully automate website deployment and CI/CD pipeline setup via CLI

---

## 📊 CURRENT STATE ANALYSIS

### Infrastructure Status
✅ **Jenkins VM**: Running (13.70.38.89:8080)  
✅ **Azure Web App**: Running but misconfigured  
✅ **Azure Container Registry**: Active with images  
✅ **Source Code**: Complete with Dockerfile and Jenkinsfile  

### Issues Identified
❌ **Web App Container**: Points to `nginx:alpine` instead of `acrvrcampusviewerdev.azurecr.io/vr-campus-viewer:latest`  
❌ **ACR Credentials Not Configured**: Web app can't pull from private ACR  
❌ **Jenkins Credentials**: Not configured (needed by Jenkinsfile)  
❌ **Jenkins Pipeline Job**: Doesn't exist  
❌ **GitHub Webhook**: Not configured  

### Resources Available
- ✅ Jenkinsfile (complete CI/CD pipeline definition)
- ✅ Dockerfile (nginx-based with VR Campus Viewer app)
- ✅ Application files (index.html, .glb model, audio files)
- ✅ JENKINS_CREDENTIALS.txt (all secrets)
- ✅ Azure Service Principal (for deployments)
- ✅ ACR with pre-built images (latest, v1)

---

## 🎯 AUTOMATION STRATEGY

### Phase 1: Deploy Website (Quick Win - 2 minutes)
**Goal**: Get website live immediately with existing image

**Steps**:
1. Configure Web App with ACR credentials
2. Update container image to use vr-campus-viewer:latest
3. Restart web app
4. Verify website is accessible

**Commands**:
```bash
# Configure ACR credentials on Web App
az webapp config container set \
  --name app-vr-campus-viewer-dev \
  --resource-group rg-vr-campus-viewer-dev \
  --docker-custom-image-name acrvrcampusviewerdev.azurecr.io/vr-campus-viewer:latest \
  --docker-registry-server-url https://acrvrcampusviewerdev.azurecr.io \
  --docker-registry-server-user acrvrcampusviewerdev \
  --docker-registry-server-password <ACR_PASSWORD>

# Restart to apply changes
az webapp restart \
  --name app-vr-campus-viewer-dev \
  --resource-group rg-vr-campus-viewer-dev

# Wait and verify
sleep 60
curl -I https://app-vr-campus-viewer-dev.azurewebsites.net
```

**Expected Result**: Website live at https://app-vr-campus-viewer-dev.azurewebsites.net

---

### Phase 2: Configure Jenkins Credentials (5 minutes)
**Goal**: Add all required credentials to Jenkins via Groovy scripts

**Required Credentials** (from Jenkinsfile):
1. `azure-service-principal` - Secret text (JSON format)
2. `acr-login-server` - Secret text
3. `acr-username` - Secret text  
4. `acr-password` - Secret text
5. `azure-resource-group` - Secret text
6. `azure-webapp-name` - Secret text

**Method**: Create Groovy init script to add credentials programmatically

**Script Location**: `/var/lib/jenkins/init.groovy.d/03-configure-credentials.groovy`

**Groovy Script Structure**:
```groovy
import jenkins.model.*
import com.cloudbees.plugins.credentials.*
import com.cloudbees.plugins.credentials.domains.*
import org.jenkinsci.plugins.plaincredentials.impl.*
import hudson.util.Secret

def instance = Jenkins.getInstance()
def domain = Domain.global()
def store = instance.getExtensionList('com.cloudbees.plugins.credentials.SystemCredentialsProvider')[0].getStore()

// Add Secret Text credentials
def addSecretText(id, secret, description) {
    def cred = new StringCredentialsImpl(
        CredentialsScope.GLOBAL,
        id,
        description,
        Secret.fromString(secret)
    )
    store.addCredentials(domain, cred)
}

// Add all credentials
addSecretText('azure-service-principal', '{"subscriptionId":"..."}', 'Azure SP')
addSecretText('acr-login-server', 'acrvrcampusviewerdev.azurecr.io', 'ACR Server')
// ... etc
```

---

### Phase 3: Install Required Jenkins Plugins (3 minutes)
**Goal**: Ensure all plugins needed by Jenkinsfile are installed

**Required Plugins**:
- `git` - Git integration (likely already installed)
- `github` - GitHub integration
- `docker-workflow` - Docker pipeline support (used by Jenkinsfile)
- `workflow-aggregator` - Pipeline plugin bundle
- `credentials-binding` - Credentials in pipeline (used extensively)
- `azure-cli` - Azure CLI plugin (optional, we use shell commands)

**Method**: Groovy script or Jenkins CLI

**Jenkins CLI Method**:
```bash
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 \
  -auth admin:admin123 \
  install-plugin docker-workflow github workflow-aggregator credentials-binding \
  -restart
```

---

### Phase 4: Create Jenkins Pipeline Job (5 minutes)
**Goal**: Create pipeline job pointing to GitHub repo with Jenkinsfile

**Method**: Jenkins Job DSL or XML config file

**Job Configuration XML**:
```xml
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job">
  <description>VR Campus Viewer CI/CD Pipeline</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <com.coravy.hudson.plugins.github.GithubProjectProperty>
      <projectUrl>https://github.com/CodesbyBalaji/Devops_project/</projectUrl>
    </com.coravy.hudson.plugins.github.GithubProjectProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition">
    <scm class="hudson.plugins.git.GitSCM">
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>https://github.com/CodesbyBalaji/Devops_project.git</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers>
    <com.cloudbees.jenkins.GitHubPushTrigger>
      <spec></spec>
    </com.cloudbees.jenkins.GitHubPushTrigger>
  </triggers>
</flow-definition>
```

**Create via CLI**:
```bash
# Upload job config
cat job-config.xml | java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 \
  -auth admin:admin123 \
  create-job vr-campus-viewer-pipeline
```

---

### Phase 5: Configure GitHub Webhook (2 minutes)
**Goal**: Enable automatic builds on git push

**Method**: GitHub API call with Personal Access Token

**GitHub API**:
```bash
curl -X POST \
  -H "Authorization: token <GITHUB_TOKEN>" \
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

**Alternative**: Manual configuration (requires user action)

---

### Phase 6: Trigger First Build (1 minute)
**Goal**: Run pipeline to verify everything works

**Method**: Jenkins CLI or API call

```bash
# Trigger build via CLI
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 \
  -auth admin:admin123 \
  build vr-campus-viewer-pipeline \
  -s -v

# Or via API
curl -X POST http://13.70.38.89:8080/job/vr-campus-viewer-pipeline/build \
  --user admin:admin123
```

---

## 🚨 RISK ANALYSIS & MITIGATION

### Risk 1: Jenkins Plugins Not Available
**Impact**: Pipeline fails to run  
**Mitigation**: Pre-check plugin availability, install via update center if needed  
**Fallback**: Manual plugin installation via Web UI

### Risk 2: Credentials Format Issues
**Impact**: Pipeline can't access Azure/ACR  
**Mitigation**: Validate credential format before adding, test each credential  
**Fallback**: Add credentials manually via Web UI

### Risk 3: GitHub Webhook Creation Fails
**Impact**: No automatic builds on push  
**Mitigation**: Requires GitHub Personal Access Token with repo:hooks permission  
**Fallback**: Manual webhook configuration (1 minute via GitHub UI)

### Risk 4: Azure Service Principal Permissions
**Impact**: Deployment fails  
**Mitigation**: Verify SP has Contributor role on resource group  
**Fallback**: Re-assign permissions via Azure portal

### Risk 5: Docker Build on Jenkins VM
**Impact**: Build fails due to resource constraints  
**Mitigation**: Jenkins VM has 2 vCPUs, 4GB RAM - should be sufficient  
**Fallback**: Increase VM size if needed

---

## 📋 EXECUTION CHECKLIST

### Pre-Execution Validation
- [ ] Verify Jenkins is running and accessible
- [ ] Confirm ACR images exist (vr-campus-viewer:latest)
- [ ] Validate all credentials in JENKINS_CREDENTIALS.txt
- [ ] Check Azure CLI logged in with correct subscription
- [ ] Ensure SSH access to Jenkins VM working
- [ ] Verify GitHub repository is accessible

### Phase 1 - Website Deployment
- [ ] Configure ACR credentials on Web App
- [ ] Update Web App container image
- [ ] Restart Web App
- [ ] Wait 60 seconds for container startup
- [ ] Verify website responds with HTTP 200
- [ ] Test VR Campus Viewer loads correctly

### Phase 2 - Jenkins Credentials
- [ ] Create Groovy script for credential configuration
- [ ] Upload script to Jenkins VM
- [ ] Execute script or restart Jenkins
- [ ] Verify credentials exist via Jenkins API
- [ ] Test credential retrieval

### Phase 3 - Jenkins Plugins
- [ ] Check currently installed plugins
- [ ] Identify missing required plugins
- [ ] Install missing plugins via CLI
- [ ] Wait for installation to complete
- [ ] Restart Jenkins if required
- [ ] Verify all plugins active

### Phase 4 - Pipeline Job
- [ ] Create job XML configuration file
- [ ] Upload to Jenkins via CLI
- [ ] Verify job appears in Jenkins UI
- [ ] Check job configuration is correct
- [ ] Validate Jenkinsfile path

### Phase 5 - GitHub Webhook
- [ ] Obtain GitHub Personal Access Token (if available)
- [ ] Create webhook via API or note manual steps
- [ ] Test webhook delivery
- [ ] Verify Jenkins receives webhook events

### Phase 6 - First Build
- [ ] Trigger pipeline build
- [ ] Monitor build progress
- [ ] Check each stage executes successfully
- [ ] Verify container pushed to ACR
- [ ] Confirm deployment to Web App
- [ ] Validate website updates with new build

### Post-Execution Validation
- [ ] Website accessible and functional
- [ ] Jenkins pipeline job exists and runs
- [ ] Credentials working in pipeline
- [ ] Docker build succeeds
- [ ] ACR push succeeds
- [ ] Azure deployment succeeds
- [ ] Health check passes
- [ ] GitHub webhook triggers builds

---

## 🔄 ROLLBACK PLAN

If automation fails:

### Website Rollback
```bash
# Revert to previous image
az webapp config container set \
  --name app-vr-campus-viewer-dev \
  --resource-group rg-vr-campus-viewer-dev \
  --docker-custom-image-name acrvrcampusviewerdev.azurecr.io/vr-campus-viewer:v1
```

### Jenkins Rollback
```bash
# Remove credentials script
ssh azureuser@13.70.38.89 "sudo rm /var/lib/jenkins/init.groovy.d/03-configure-credentials.groovy"

# Delete pipeline job
java -jar /tmp/jenkins-cli.jar -s http://localhost:8080 \
  -auth admin:admin123 \
  delete-job vr-campus-viewer-pipeline

# Restart Jenkins
ssh azureuser@13.70.38.89 "sudo systemctl restart jenkins"
```

---

## 📊 SUCCESS CRITERIA

### Must Have (Critical)
✅ Website loads successfully (HTTP 200)  
✅ VR Campus Viewer application renders  
✅ Jenkins credentials configured  
✅ Pipeline job created  

### Should Have (Important)
✅ All Jenkins plugins installed  
✅ Pipeline runs successfully once  
✅ Deployment to Azure works  

### Nice to Have (Optional)
✅ GitHub webhook configured  
✅ Automatic builds on push  
✅ Health check passes  

---

## ⏱️ ESTIMATED TIMELINE

| Phase | Task | Time | Cumulative |
|-------|------|------|------------|
| 1 | Website Deployment | 2 min | 2 min |
| 2 | Jenkins Credentials | 5 min | 7 min |
| 3 | Install Plugins | 3 min | 10 min |
| 4 | Create Pipeline Job | 5 min | 15 min |
| 5 | GitHub Webhook | 2 min | 17 min |
| 6 | First Build Test | 5 min | 22 min |
| | **TOTAL** | **22 min** | |

---

## 🎯 EXECUTION DECISION

**Recommended Approach**: Phased execution with validation after each phase

**Benefits**:
- Can stop if issues occur
- Validate each component works
- Easy to identify problem areas
- Minimal risk of breaking existing setup

**Alternative**: All-at-once automation (higher risk)

---

**Status**: PLAN COMPLETE - READY FOR EXECUTION  
**Next Action**: Proceed with Phase 1 - Website Deployment

#!/bin/bash

set -e

echo "=========================================="
echo "Jenkins Pipeline Setup Script"
echo "=========================================="
echo ""

# Check if running with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Please run with sudo: sudo ./setup_jenkins_pipeline.sh"
    exit 1
fi

# Load installation info
if [ -f /tmp/mlops_install_info.txt ]; then
    source /tmp/mlops_install_info.txt
else
    echo "Installation info not found. Please run ./install.sh first."
    exit 1
fi

# Get current directory
WORKSPACE_DIR=$(pwd)

echo "Detected Configuration:"
echo "  Public IP: $PUBLIC_IP"
echo "  Workspace: $WORKSPACE_DIR"
echo "  User: $ACTUAL_USER"
echo ""

# Check if Jenkins is running
if ! systemctl is-active --quiet jenkins; then
    echo "Jenkins is not running. Starting..."
    systemctl start jenkins
    sleep 10
fi

echo "Checking Jenkins status..."
if ! curl -s http://localhost:8080 > /dev/null; then
    echo "Jenkins is not accessible yet. Waiting..."
    sleep 20
fi

echo ""
echo "=========================================="
echo "Jenkins Setup Instructions"
echo "=========================================="
echo ""
echo "Before running this script, you must:"
echo ""
echo "1. Open Jenkins: http://${PUBLIC_IP}:8080"
echo ""
echo "2. Complete initial setup:"
echo "   - Enter admin password"
echo "   - Install suggested plugins"
echo "   - Create admin user (or skip)"
echo ""
echo "3. Install required plugins:"
echo "   - Go to: Manage Jenkins → Plugins → Available"
echo "   - Search and install:"
echo "     ✓ Pipeline"
echo "     ✓ Git"
echo "     ✓ Docker Pipeline"
echo "     ✓ Workspace Cleanup"
echo ""
read -p "Have you completed the initial Jenkins setup? (yes/no): " SETUP_DONE

if [ "$SETUP_DONE" != "yes" ]; then
    echo ""
    echo "Please complete Jenkins setup first, then run this script again."
    echo ""
    echo "Quick setup:"
    echo "  1. Open: http://${PUBLIC_IP}:8080"
    echo "  2. Password: $JENKINS_PASSWORD"
    echo "  3. Install suggested plugins"
    echo "  4. Create admin user"
    echo "  5. Run this script again"
    echo ""
    exit 0
fi

echo ""
echo "Creating Jenkins pipeline job..."
echo ""

# Get Jenkins credentials
read -p "Enter Jenkins admin username [admin]: " JENKINS_USER
JENKINS_USER=${JENKINS_USER:-admin}

read -sp "Enter Jenkins admin password: " JENKINS_PASS
echo ""

# Create Jenkins job XML
cat > /tmp/mlops-pipeline-config.xml <<'EOF'
<?xml version='1.1' encoding='UTF-8'?>
<flow-definition plugin="workflow-job@2.40">
  <description>MLOps Pipeline with A/B Testing and Monitoring</description>
  <keepDependencies>false</keepDependencies>
  <properties>
    <org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
      <triggers>
        <hudson.triggers.SCMTrigger>
          <spec>H/5 * * * *</spec>
          <ignorePostCommitHooks>false</ignorePostCommitHooks>
        </hudson.triggers.SCMTrigger>
      </triggers>
    </org.jenkinsci.plugins.workflow.job.properties.PipelineTriggersJobProperty>
  </properties>
  <definition class="org.jenkinsci.plugins.workflow.cps.CpsScmFlowDefinition" plugin="workflow-cps@2.90">
    <scm class="hudson.plugins.git.GitSCM" plugin="git@4.10.0">
      <configVersion>2</configVersion>
      <userRemoteConfigs>
        <hudson.plugins.git.UserRemoteConfig>
          <url>WORKSPACE_DIR_PLACEHOLDER</url>
        </hudson.plugins.git.UserRemoteConfig>
      </userRemoteConfigs>
      <branches>
        <hudson.plugins.git.BranchSpec>
          <name>*/main</name>
        </hudson.plugins.git.BranchSpec>
        <hudson.plugins.git.BranchSpec>
          <name>*/master</name>
        </hudson.plugins.git.BranchSpec>
      </branches>
      <doGenerateSubmoduleConfigurations>false</doGenerateSubmoduleConfigurations>
      <submoduleCfg class="list"/>
      <extensions/>
    </scm>
    <scriptPath>Jenkinsfile</scriptPath>
    <lightweight>true</lightweight>
  </definition>
  <triggers/>
  <disabled>false</disabled>
</flow-definition>
EOF

# Replace workspace directory
sed -i "s|WORKSPACE_DIR_PLACEHOLDER|$WORKSPACE_DIR|g" /tmp/mlops-pipeline-config.xml

# Create job via Jenkins CLI
echo ""
echo "Creating Jenkins job via API..."

# Try to create the job
RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "http://localhost:8080/createItem?name=mlops-pipeline" \
    --user "$JENKINS_USER:$JENKINS_PASS" \
    --header "Content-Type: application/xml" \
    --data-binary @/tmp/mlops-pipeline-config.xml 2>&1)

HTTP_CODE=$(echo "$RESPONSE" | tail -n 1)
BODY=$(echo "$RESPONSE" | head -n -1)

if [ "$HTTP_CODE" == "200" ]; then
    echo "✓ Jenkins pipeline job created successfully!"
elif [ "$HTTP_CODE" == "400" ] && echo "$BODY" | grep -q "already exists"; then
    echo "✓ Jenkins pipeline job already exists"
else
    echo "✗ Failed to create Jenkins job (HTTP $HTTP_CODE)"
    echo "Response: $BODY"
    echo ""
    echo "Manual setup required:"
    echo "1. Go to Jenkins: http://${PUBLIC_IP}:8080"
    echo "2. Click 'New Item'"
    echo "3. Name: mlops-pipeline"
    echo "4. Type: Pipeline"
    echo "5. Pipeline script from SCM"
    echo "6. SCM: Git"
    echo "7. Repository URL: $WORKSPACE_DIR"
    echo "8. Script Path: Jenkinsfile"
    exit 1
fi

# Trigger first build
echo ""
echo "Triggering first build..."
sleep 2

BUILD_RESPONSE=$(curl -s -w "\n%{http_code}" -X POST \
    "http://localhost:8080/job/mlops-pipeline/build" \
    --user "$JENKINS_USER:$JENKINS_PASS" 2>&1)

BUILD_CODE=$(echo "$BUILD_RESPONSE" | tail -n 1)

if [ "$BUILD_CODE" == "201" ]; then
    echo "✓ Build triggered successfully!"
else
    echo "⚠ Could not trigger build automatically (HTTP $BUILD_CODE)"
    echo "You can trigger it manually from Jenkins UI"
fi

echo ""
echo "=========================================="
echo "Jenkins Pipeline Setup Complete!"
echo "=========================================="
echo ""
echo "Access your Jenkins pipeline:"
echo "  http://${PUBLIC_IP}:8080/job/mlops-pipeline/"
echo ""
echo "The pipeline will:"
echo "  1. Checkout code"
echo "  2. Install dependencies"
echo "  3. Train models"
echo "  4. Run tests"
echo "  5. Build Docker images"
echo "  6. Deploy services"
echo "  7. Run health checks"
echo ""
echo "After deployment, access your services:"
echo "  Web UI:     http://${PUBLIC_IP}:8501"
echo "  API:        http://${PUBLIC_IP}:5000"
echo "  Prometheus: http://${PUBLIC_IP}:9090"
echo "  Jenkins:    http://${PUBLIC_IP}:8080"
echo ""
echo "To monitor the build:"
echo "  1. Go to: http://${PUBLIC_IP}:8080/job/mlops-pipeline/"
echo "  2. Click on the build number"
echo "  3. Click 'Console Output'"
echo ""
echo "=========================================="

# Clean up
rm -f /tmp/mlops-pipeline-config.xml

# Save service URLs
cat > service_urls.txt <<EOF
MLOps Pipeline Service URLs
============================

Web UI:     http://${PUBLIC_IP}:8501
API:        http://${PUBLIC_IP}:5000
Prometheus: http://${PUBLIC_IP}:9090
Jenkins:    http://${PUBLIC_IP}:8080

Test API:
curl -X POST http://${PUBLIC_IP}:5000/predict \\
  -H "Content-Type: application/json" \\
  -d '{"features": [5.1, 3.5, 1.4, 0.2]}'

Generated: $(date)
EOF

echo "Service URLs saved to: service_urls.txt"
echo ""
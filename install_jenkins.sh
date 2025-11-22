#!/bin/bash

# Jenkins Installation Script for MLOps Pipeline
# Works on Amazon Linux and RHEL

set -e

echo "=========================================="
echo "Jenkins Installation for MLOps Pipeline"
echo "=========================================="
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "Please run with sudo: sudo ./install_jenkins.sh"
    exit 1
fi

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
    echo "Detected OS: $OS"
else
    echo "Cannot detect OS. Assuming RHEL-based system."
    OS="rhel"
fi

# Step 1: Install Java (Jenkins requirement)
echo ""
echo "[1/5] Installing Java..."
if command -v yum &> /dev/null; then
    yum install -y java-11-openjdk java-11-openjdk-devel
elif command -v dnf &> /dev/null; then
    dnf install -y java-11-openjdk java-11-openjdk-devel
fi

# Verify Java installation
java -version

# Step 2: Add Jenkins repository
echo ""
echo "[2/5] Adding Jenkins repository..."
wget -O /etc/yum.repos.d/jenkins.repo \
    https://pkg.jenkins.io/redhat-stable/jenkins.repo
rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

# Step 3: Install Jenkins
echo ""
echo "[3/5] Installing Jenkins..."
if command -v yum &> /dev/null; then
    yum install -y jenkins
elif command -v dnf &> /dev/null; then
    dnf install -y jenkins
fi

# Step 4: Start Jenkins service
echo ""
echo "[4/5] Starting Jenkins service..."
systemctl daemon-reload
systemctl start jenkins
systemctl enable jenkins

# Step 5: Wait for Jenkins to initialize
echo ""
echo "[5/5] Waiting for Jenkins to initialize (30 seconds)..."
sleep 30

# Get public IP
PUBLIC_IP=$(curl -s --connect-timeout 2 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || curl -s https://api.ipify.org 2>/dev/null || hostname -I | awk '{print $1}')

# Get initial admin password
JENKINS_PASSWORD=$(cat /var/lib/jenkins/secrets/initialAdminPassword 2>/dev/null || echo "Not found - Jenkins may still be starting")

echo ""
echo "=========================================="
echo "Jenkins Installation Complete!"
echo "=========================================="
echo ""
echo "Access Jenkins at:"
echo "  http://${PUBLIC_IP}:8080"
echo ""
echo "Initial Admin Password:"
echo "  ${JENKINS_PASSWORD}"
echo ""
echo "Next Steps:"
echo "  1. Open http://${PUBLIC_IP}:8080 in your browser"
echo "  2. Enter the password above"
echo "  3. Install suggested plugins"
echo "  4. Create admin user"
echo "  5. Create a Pipeline job pointing to the Jenkinsfile"
echo ""
echo "Note: If on AWS, make sure Security Group allows port 8080"
echo ""
echo "To check Jenkins status:"
echo "  sudo systemctl status jenkins"
echo ""
echo "To view Jenkins logs:"
echo "  sudo journalctl -u jenkins -f"
echo ""
echo "=========================================="

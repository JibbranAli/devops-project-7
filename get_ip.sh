#!/bin/bash

# Simple script to get and display your public IP address

echo "Detecting your public IP address..."
echo ""

# Try multiple methods
IP=""

# Method 1: AWS metadata (works on EC2)
IP=$(curl -s --connect-timeout 2 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "")

if [ -n "$IP" ] && [ "$IP" != "127.0.0.1" ]; then
    echo "✓ Detected via AWS metadata service"
    echo ""
    echo "Your Public IP: $IP"
    echo ""
    echo "Access your services at:"
    echo "  Web UI:     http://$IP:8501"
    echo "  API:        http://$IP:5000"
    echo "  Prometheus: http://$IP:9090"
    echo ""
    exit 0
fi

# Method 2: External service
IP=$(curl -s --connect-timeout 3 https://api.ipify.org 2>/dev/null || echo "")

if [ -n "$IP" ] && [ "$IP" != "127.0.0.1" ]; then
    echo "✓ Detected via external service"
    echo ""
    echo "Your Public IP: $IP"
    echo ""
    echo "Access your services at:"
    echo "  Web UI:     http://$IP:8501"
    echo "  API:        http://$IP:5000"
    echo "  Prometheus: http://$IP:9090"
    echo ""
    exit 0
fi

# Method 3: Local network IP
IP=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "")

if [ -n "$IP" ] && [ "$IP" != "127.0.0.1" ]; then
    echo "✓ Detected local network IP"
    echo ""
    echo "Your IP: $IP"
    echo ""
    echo "Access your services at:"
    echo "  Web UI:     http://$IP:8501"
    echo "  API:        http://$IP:5000"
    echo "  Prometheus: http://$IP:9090"
    echo ""
    echo "Note: This is a local IP. If accessing from outside,"
    echo "you may need to use your public IP instead."
    echo ""
    exit 0
fi

# Fallback
echo "✗ Could not detect IP address automatically"
echo ""
echo "Try these commands manually:"
echo "  curl -s http://169.254.169.254/latest/meta-data/public-ipv4"
echo "  curl -s https://api.ipify.org"
echo ""

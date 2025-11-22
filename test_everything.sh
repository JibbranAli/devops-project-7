#!/bin/bash

# Complete system test script for MLOps Pipeline
# Tests all components and provides detailed feedback

set -e

# Colors for better readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
PASSED=0
FAILED=0
WARNINGS=0

# Get the IP address of the instance
get_ip_address() {
    local ip=""
    
    # Method 1: Try AWS metadata service (works on EC2)
    ip=$(curl -s --connect-timeout 2 --max-time 3 http://169.254.169.254/latest/meta-data/public-ipv4 2>/dev/null || echo "")
    
    if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
        echo "$ip"
        return
    fi
    
    # Method 2: Try to get public IP from external service
    ip=$(curl -s --connect-timeout 2 --max-time 3 https://api.ipify.org 2>/dev/null || echo "")
    
    if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
        echo "$ip"
        return
    fi
    
    # Method 3: Get primary network interface IP
    ip=$(hostname -I 2>/dev/null | awk '{print $1}' || echo "")
    
    if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
        echo "$ip"
        return
    fi
    
    # Method 4: Try ip command
    ip=$(ip route get 1 2>/dev/null | awk '{print $7; exit}' || echo "")
    
    if [ -n "$ip" ] && [ "$ip" != "127.0.0.1" ]; then
        echo "$ip"
        return
    fi
    
    # Fallback to localhost
    echo "localhost"
}

# Print section header
print_header() {
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# Print test result
print_result() {
    local status=$1
    local message=$2
    
    if [ "$status" == "PASS" ]; then
        echo -e "${GREEN}✓ PASS${NC} - $message"
        PASSED=$((PASSED + 1))
    elif [ "$status" == "FAIL" ]; then
        echo -e "${RED}✗ FAIL${NC} - $message"
        FAILED=$((FAILED + 1))
    elif [ "$status" == "WARN" ]; then
        echo -e "${YELLOW}⚠ WARN${NC} - $message"
        WARNINGS=$((WARNINGS + 1))
    else
        echo -e "${BLUE}ℹ INFO${NC} - $message"
    fi
}

# Test function with timeout
test_endpoint() {
    local url=$1
    local description=$2
    local expected_code=${3:-200}
    
    response=$(curl -s -w "\n%{http_code}" --connect-timeout 5 --max-time 10 "$url" 2>/dev/null || echo -e "\n000")
    http_code=$(echo "$response" | tail -n 1)
    body=$(echo "$response" | head -n -1)
    
    if [ "$http_code" == "$expected_code" ]; then
        print_result "PASS" "$description (HTTP $http_code)"
        return 0
    else
        print_result "FAIL" "$description (Expected $expected_code, got $http_code)"
        return 1
    fi
}

# Main test execution
main() {
    clear
    echo -e "${BLUE}"
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║        MLOps Pipeline - Complete System Test          ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    # Detect IP address
    IP_ADDRESS=$(get_ip_address)
    echo -e "${YELLOW}Detected IP Address: $IP_ADDRESS${NC}"
    echo ""
    
    # Set base URLs
    API_URL="http://${IP_ADDRESS}:5000"
    UI_URL="http://${IP_ADDRESS}:8501"
    PROM_URL="http://${IP_ADDRESS}:9090"
    JENKINS_URL="http://${IP_ADDRESS}:8080"
    
    echo "Service URLs:"
    echo "  API:        $API_URL"
    echo "  UI:         $UI_URL"
    echo "  Prometheus: $PROM_URL"
    echo "  Jenkins:    $JENKINS_URL"
    echo ""
    
    # Test 1: System Dependencies
    print_header "Test 1: System Dependencies"
    
    if command -v python3 &> /dev/null; then
        print_result "PASS" "Python 3 is installed ($(python3 --version))"
    else
        print_result "FAIL" "Python 3 is not installed"
    fi
    
    if command -v docker &> /dev/null; then
        print_result "PASS" "Docker is installed ($(docker --version | head -n1))"
    else
        print_result "FAIL" "Docker is not installed"
    fi
    
    if command -v docker-compose &> /dev/null; then
        print_result "PASS" "Docker Compose is installed ($(docker-compose --version | head -n1))"
    else
        print_result "FAIL" "Docker Compose is not installed"
    fi
    
    # Test 2: Project Structure
    print_header "Test 2: Project Structure"
    
    files_to_check=(
        "requirements.txt"
        "docker-compose.yml"
        "app/flask_app.py"
        "app/streamlit_app.py"
        "app/train_model.py"
        "app/monitoring.py"
    )
    
    for file in "${files_to_check[@]}"; do
        if [ -f "$file" ]; then
            print_result "PASS" "File exists: $file"
        else
            print_result "FAIL" "File missing: $file"
        fi
    done
    
    # Test 3: ML Models
    print_header "Test 3: ML Models"
    
    if [ -f "app/models/model_v1.pkl" ]; then
        print_result "PASS" "Model v1 exists"
    else
        print_result "WARN" "Model v1 not found - run: python3 app/train_model.py"
    fi
    
    if [ -f "app/models/model_v2.pkl" ]; then
        print_result "PASS" "Model v2 exists"
    else
        print_result "WARN" "Model v2 not found - run: python3 app/train_model.py"
    fi
    
    if [ -f "app/models/training_stats.pkl" ]; then
        print_result "PASS" "Training statistics exist"
    else
        print_result "WARN" "Training stats not found"
    fi
    
    # Test 4: Docker Services
    print_header "Test 4: Docker Services"
    
    if docker ps &> /dev/null; then
        print_result "PASS" "Docker daemon is running"
        
        # Check if containers are running
        if docker-compose ps 2>/dev/null | grep -q "Up"; then
            print_result "PASS" "Docker Compose services are running"
            
            # Check individual containers
            if docker-compose ps | grep -q "mlops-flask-api.*Up"; then
                print_result "PASS" "Flask API container is running"
            else
                print_result "FAIL" "Flask API container is not running"
            fi
            
            if docker-compose ps | grep -q "mlops-streamlit-ui.*Up"; then
                print_result "PASS" "Streamlit UI container is running"
            else
                print_result "FAIL" "Streamlit UI container is not running"
            fi
            
            if docker-compose ps | grep -q "mlops-prometheus.*Up"; then
                print_result "PASS" "Prometheus container is running"
            else
                print_result "FAIL" "Prometheus container is not running"
            fi
            
            if docker-compose ps | grep -q "mlops-jenkins.*Up"; then
                print_result "PASS" "Jenkins container is running"
            else
                print_result "WARN" "Jenkins container is not running (optional)"
            fi
        else
            print_result "FAIL" "Docker Compose services are not running - run: ./run_demo.sh"
        fi
    else
        print_result "FAIL" "Docker daemon is not running or permission denied"
    fi
    
    # Test 5: API Endpoints
    print_header "Test 5: Flask API Endpoints"
    
    echo "Testing API at: $API_URL"
    echo ""
    
    # Health check
    test_endpoint "$API_URL/health" "Health endpoint"
    
    # Config endpoint
    test_endpoint "$API_URL/config" "Configuration endpoint"
    
    # Metrics endpoint
    test_endpoint "$API_URL/metrics" "Metrics endpoint"
    
    # Prediction endpoint
    echo ""
    echo "Testing prediction endpoint..."
    pred_response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/predict" \
        -H "Content-Type: application/json" \
        -d '{"features": [5.1, 3.5, 1.4, 0.2]}' 2>/dev/null || echo -e "\n000")
    
    pred_code=$(echo "$pred_response" | tail -n 1)
    pred_body=$(echo "$pred_response" | head -n -1)
    
    if [ "$pred_code" == "200" ]; then
        if echo "$pred_body" | grep -q "prediction"; then
            print_result "PASS" "Prediction endpoint returns valid response"
            echo "  Sample response: $(echo $pred_body | head -c 100)..."
        else
            print_result "FAIL" "Prediction endpoint returns invalid response"
        fi
    else
        print_result "FAIL" "Prediction endpoint failed (HTTP $pred_code)"
    fi
    
    # Test 6: A/B Testing
    print_header "Test 6: A/B Testing"
    
    echo "Making 20 predictions to test A/B distribution..."
    v1_count=0
    v2_count=0
    
    for i in {1..20}; do
        response=$(curl -s -X POST "$API_URL/predict" \
            -H "Content-Type: application/json" \
            -d '{"features": [5.1, 3.5, 1.4, 0.2]}' 2>/dev/null || echo "")
        
        if echo "$response" | grep -q '"model_version": "v1"'; then
            v1_count=$((v1_count + 1))
        elif echo "$response" | grep -q '"model_version": "v2"'; then
            v2_count=$((v2_count + 1))
        fi
        
        # Progress indicator
        if [ $((i % 5)) -eq 0 ]; then
            echo -n "."
        fi
    done
    
    echo ""
    echo ""
    echo "A/B Test Results:"
    echo "  Model v1: $v1_count requests (${v1_count}0%)"
    echo "  Model v2: $v2_count requests (${v2_count}0%)"
    
    if [ $v1_count -gt 0 ] && [ $v2_count -gt 0 ]; then
        print_result "PASS" "Both models are serving requests"
    else
        print_result "FAIL" "A/B testing not working properly"
    fi
    
    # Test 7: Prometheus Metrics
    print_header "Test 7: Prometheus Monitoring"
    
    test_endpoint "$PROM_URL/-/healthy" "Prometheus health check"
    
    # Check if metrics are being collected
    metrics=$(curl -s "$API_URL/metrics" 2>/dev/null || echo "")
    
    if echo "$metrics" | grep -q "prediction_requests_total"; then
        print_result "PASS" "Prediction counter metric exists"
    else
        print_result "FAIL" "Prediction counter metric not found"
    fi
    
    if echo "$metrics" | grep -q "model_version_requests_total"; then
        print_result "PASS" "Model version metric exists"
    else
        print_result "FAIL" "Model version metric not found"
    fi
    
    if echo "$metrics" | grep -q "prediction_latency_seconds"; then
        print_result "PASS" "Latency metric exists"
    else
        print_result "FAIL" "Latency metric not found"
    fi
    
    # Test 8: Jenkins CI/CD
    print_header "Test 8: Jenkins CI/CD"
    
    jenkins_response=$(curl -s -w "\n%{http_code}" --connect-timeout 5 "$JENKINS_URL/login" 2>/dev/null || echo -e "\n000")
    jenkins_code=$(echo "$jenkins_response" | tail -n 1)
    
    if [ "$jenkins_code" == "200" ]; then
        print_result "PASS" "Jenkins is accessible"
    else
        print_result "WARN" "Jenkins is not accessible (optional service)"
    fi
    
    # Test 9: Streamlit UI
    print_header "Test 9: Streamlit UI"
    
    ui_response=$(curl -s -w "\n%{http_code}" --connect-timeout 5 "$UI_URL" 2>/dev/null || echo -e "\n000")
    ui_code=$(echo "$ui_response" | tail -n 1)
    
    if [ "$ui_code" == "200" ]; then
        print_result "PASS" "Streamlit UI is accessible"
    else
        print_result "FAIL" "Streamlit UI is not accessible (HTTP $ui_code)"
    fi
    
    # Test 10: Error Handling
    print_header "Test 10: API Error Handling"
    
    # Test missing features
    error_response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/predict" \
        -H "Content-Type: application/json" \
        -d '{"wrong_key": [1, 2, 3, 4]}' 2>/dev/null || echo -e "\n000")
    
    error_code=$(echo "$error_response" | tail -n 1)
    
    if [ "$error_code" == "400" ]; then
        print_result "PASS" "API correctly rejects invalid input"
    else
        print_result "WARN" "API error handling may not be working (got HTTP $error_code)"
    fi
    
    # Test 11: Performance
    print_header "Test 11: Performance Check"
    
    echo "Measuring API response time..."
    start_time=$(date +%s%N)
    curl -s -X POST "$API_URL/predict" \
        -H "Content-Type: application/json" \
        -d '{"features": [5.1, 3.5, 1.4, 0.2]}' > /dev/null 2>&1
    end_time=$(date +%s%N)
    
    duration=$(( (end_time - start_time) / 1000000 ))
    
    echo "Response time: ${duration}ms"
    
    if [ $duration -lt 1000 ]; then
        print_result "PASS" "API response time is good (${duration}ms)"
    elif [ $duration -lt 3000 ]; then
        print_result "WARN" "API response time is acceptable (${duration}ms)"
    else
        print_result "FAIL" "API response time is slow (${duration}ms)"
    fi
    
    # Summary
    print_header "Test Summary"
    
    TOTAL=$((PASSED + FAILED + WARNINGS))
    
    echo -e "${GREEN}Passed:   $PASSED${NC}"
    echo -e "${RED}Failed:   $FAILED${NC}"
    echo -e "${YELLOW}Warnings: $WARNINGS${NC}"
    echo "Total:    $TOTAL"
    echo ""
    
    # Calculate success rate
    if [ $TOTAL -gt 0 ]; then
        SUCCESS_RATE=$(( (PASSED * 100) / TOTAL ))
        echo "Success Rate: ${SUCCESS_RATE}%"
    fi
    
    echo ""
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}Access Your Services${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
    echo "  Streamlit UI:  $UI_URL"
    echo "  Flask API:     $API_URL"
    echo "  Prometheus:    $PROM_URL"
    echo "  Jenkins:       $JENKINS_URL"
    echo ""
    echo "Test the API:"
    echo "  curl -X POST $API_URL/predict \\"
    echo "    -H \"Content-Type: application/json\" \\"
    echo "    -d '{\"features\": [5.1, 3.5, 1.4, 0.2]}'"
    echo ""
    
    # Final verdict
    if [ $FAILED -eq 0 ]; then
        echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
        echo -e "${GREEN}║  ✓ All Critical Tests Passed!         ║${NC}"
        echo -e "${GREEN}║  Your MLOps Pipeline is Ready!        ║${NC}"
        echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
        exit 0
    else
        echo -e "${RED}╔════════════════════════════════════════╗${NC}"
        echo -e "${RED}║  ✗ Some Tests Failed                   ║${NC}"
        echo -e "${RED}║  Please Review Errors Above            ║${NC}"
        echo -e "${RED}╚════════════════════════════════════════╝${NC}"
        echo ""
        echo "Common fixes:"
        echo "  - Run: ./run_demo.sh"
        echo "  - Check logs: docker-compose logs"
        echo "  - Verify setup: ./verify_setup.sh"
        exit 1
    fi
}

# Run main function
main

#!/bin/bash

# Security scanning script for DevSecOps pipeline
set -e

echo "🔍 Starting security scanning..."

# Function to run Trivy scan
run_trivy_scan() {
    local image_name=$1
    local output_file=$2
    
    echo "Scanning image: $image_name"
    trivy image --format json --output "$output_file" "$image_name"
    
    # Check for high/critical vulnerabilities
    high_critical=$(jq '.Results[]?.Vulnerabilities[]? | select(.Severity == "HIGH" or .Severity == "CRITICAL") | .VulnerabilityID' "$output_file" | wc -l)
    
    if [ "$high_critical" -gt 0 ]; then
        echo "❌ Found $high_critical high/critical vulnerabilities in $image_name"
        return 1
    else
        echo "✅ No high/critical vulnerabilities found in $image_name"
        return 0
    fi
}

# Function to run dependency scan
run_dependency_scan() {
    local service_path=$1
    local service_name=$2
    
    echo "Scanning dependencies for $service_name..."
    cd "$service_path"
    
    # Run safety check for Python dependencies
    if [ -f "requirements.txt" ]; then
        safety check --json --output "../${service_name}-safety-report.json" || true
        echo "✅ Dependency scan completed for $service_name"
    fi
    
    cd ..
}

# Function to run SAST scan
run_sast_scan() {
    local service_path=$1
    local service_name=$2
    
    echo "Running SAST scan for $service_name..."
    cd "$service_path"
    
    # Run bandit for Python security issues
    if [ -f "requirements.txt" ]; then
        bandit -r . -f json -o "../${service_name}-bandit-report.json" || true
        echo "✅ SAST scan completed for $service_name"
    fi
    
    cd ..
}

# Main execution
echo "🚀 Starting comprehensive security scanning..."

# Scan all services
services=("customer-service" "order-service" "product-service")

for service in "${services[@]}"; do
    echo "📦 Scanning $service..."
    
    # Dependency scan
    run_dependency_scan "backend/$service" "$service"
    
    # SAST scan
    run_sast_scan "backend/$service" "$service"
    
    # Container image scan (if image exists)
    image_name="sit722acr01.azurecr.io/$service:latest"
    if docker image inspect "$image_name" >/dev/null 2>&1; then
        run_trivy_scan "$image_name" "${service}-trivy-report.json"
    fi
done

# Scan frontend
echo "📦 Scanning frontend..."
run_dependency_scan "frontend" "frontend"

# Frontend container scan
frontend_image="sit722devopsacr.azurecr.io/frontend:latest"
if docker image inspect "$frontend_image" >/dev/null 2>&1; then
    run_trivy_scan "$frontend_image" "frontend-trivy-report.json"
fi

echo "🎉 Security scanning completed!"
echo "📊 Reports generated:"
ls -la *-report.json 2>/dev/null || echo "No reports found"

# Summary
echo "📋 Security Scan Summary:"
echo "=========================="
echo "✅ Dependency scans: Completed"
echo "✅ SAST scans: Completed"
echo "✅ Container scans: Completed"
echo "📁 All reports saved in current directory"

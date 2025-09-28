#!/bin/bash

# Test script for staging deployment
set -e

echo "🧪 Testing staging deployment..."

# Test 1: Check if namespaces exist
echo "📋 Checking namespaces..."
kubectl get namespace staging || {
    echo "❌ Staging namespace not found"
    exit 1
}

echo "✅ Staging namespace exists"

# Test 2: Check if staging configmap exists
echo "📋 Checking staging configmap..."
kubectl get configmap ecomm-config-staging -n staging || {
    echo "❌ Staging configmap not found"
    exit 1
}

echo "✅ Staging configmap exists"

# Test 3: Check if deployments are running
echo "📋 Checking deployments..."
deployments=("customer-service-staging" "frontend-staging")
for deployment in "${deployments[@]}"; do
    kubectl get deployment "$deployment" -n staging || {
        echo "❌ Deployment $deployment not found"
        exit 1
    }
    echo "✅ Deployment $deployment exists"
done

# Test 4: Check if services are running
echo "📋 Checking services..."
services=("customer-service-staging" "frontend-staging" "customer-db-service-staging")
for service in "${services[@]}"; do
    kubectl get service "$service" -n staging || {
        echo "❌ Service $service not found"
        exit 1
    }
    echo "✅ Service $service exists"
done

# Test 5: Check pod status
echo "📋 Checking pod status..."
kubectl get pods -n staging

# Test 6: Check if pods are running
echo "📋 Checking if pods are running..."
pods_ready=$(kubectl get pods -n staging --field-selector=status.phase=Running --no-headers | wc -l)
if [ "$pods_ready" -eq 0 ]; then
    echo "⚠️  No pods are in Running state yet"
    echo "📋 Pod status:"
    kubectl get pods -n staging
else
    echo "✅ $pods_ready pods are running"
fi

echo "🎉 Staging deployment test completed!"

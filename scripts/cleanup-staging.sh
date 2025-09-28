#!/bin/bash

# Cleanup script for staging deployment
set -e

echo "🧹 Cleaning up staging deployment..."

# Delete all deployments in staging namespace
echo "📦 Deleting deployments..."
kubectl delete deployment --all -n staging --ignore-not-found=true

# Delete all services in staging namespace
echo "🔗 Deleting services..."
kubectl delete service --all -n staging --ignore-not-found=true

# Delete all pods in staging namespace
echo "🚀 Deleting pods..."
kubectl delete pods --all -n staging --ignore-not-found=true

# Delete configmaps
echo "⚙️  Deleting configmaps..."
kubectl delete configmap --all -n staging --ignore-not-found=true

# Wait a moment for cleanup
echo "⏳ Waiting for cleanup to complete..."
sleep 10

# Check what's left
echo "📋 Remaining resources in staging namespace:"
kubectl get all -n staging

echo "🎉 Cleanup completed!"

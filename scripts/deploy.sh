#!/bin/bash

# Deployment script for DevSecOps pipeline
set -e

# Configuration
ENVIRONMENT=${1:-staging}
NAMESPACE=${2:-$ENVIRONMENT}
IMAGE_TAG=${3:-latest}

echo "🚀 Starting deployment to $ENVIRONMENT environment..."
echo "📦 Namespace: $NAMESPACE"
echo "🏷️  Image tag: $IMAGE_TAG"

# Function to update image tags in manifests
update_image_tags() {
    local manifest_file=$1
    local service_name=$2
    local new_tag=$3
    
    echo "Updating $service_name image tag to $new_tag in $manifest_file"
    
    if [ "$service_name" = "frontend" ]; then
        sed -i "s|sit722devopsacr.azurecr.io/frontend:.*|sit722devopsacr.azurecr.io/frontend:$new_tag|g" "$manifest_file"
    else
        sed -i "s|sit722acr01.azurecr.io/$service_name:.*|sit722acr01.azurecr.io/$service_name:$new_tag|g" "$manifest_file"
    fi
}

# Function to update namespace in manifests
update_namespace() {
    local manifest_file=$1
    local namespace=$2
    
    echo "Updating namespace to $namespace in $manifest_file"
    sed -i "s/namespace: .*/namespace: $namespace/g" "$manifest_file"
}

# Function to deploy service
deploy_service() {
    local service_name=$1
    local manifest_file=$2
    
    echo "📦 Deploying $service_name..."
    
    # Update image tag
    update_image_tags "$manifest_file" "$service_name" "$IMAGE_TAG"
    
    # Update namespace
    update_namespace "$manifest_file" "$NAMESPACE"
    
    # Apply manifest
    kubectl apply -f "$manifest_file"
    
    # Wait for deployment
    echo "⏳ Waiting for $service_name deployment to be ready..."
    kubectl wait --for=condition=available --timeout=300s deployment/$service_name -n "$NAMESPACE" || {
        echo "❌ Deployment failed for $service_name"
        kubectl describe deployment/$service_name -n "$NAMESPACE"
        kubectl logs -l app=$service_name -n "$NAMESPACE" --tail=50
        exit 1
    }
    
    echo "✅ $service_name deployed successfully"
}

# Function to run health checks
run_health_checks() {
    local namespace=$1
    
    echo "🏥 Running health checks..."
    
    # Get service endpoints
    services=$(kubectl get services -n "$namespace" -o jsonpath='{.items[*].metadata.name}')
    
    for service in $services; do
        echo "Checking health of $service..."
        
        # Get service port
        port=$(kubectl get service "$service" -n "$namespace" -o jsonpath='{.spec.ports[0].port}')
        
        # Get service IP
        service_ip=$(kubectl get service "$service" -n "$namespace" -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
        
        if [ -n "$service_ip" ] && [ "$service_ip" != "null" ]; then
            echo "Testing $service at http://$service_ip:$port"
            curl -f "http://$service_ip:$port" || echo "⚠️  Health check failed for $service"
        else
            echo "⚠️  No external IP found for $service"
        fi
    done
}

# Main deployment logic
echo "🔧 Preparing deployment..."

# Create namespace if it doesn't exist
kubectl create namespace "$NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Deploy services
deploy_service "customer-service" "k8s/customer-service.yaml"
deploy_service "order-service" "k8s/order-service.yaml"
deploy_service "product-service" "k8s/product-service.yaml"
deploy_service "frontend" "k8s/frontend.yaml"

# Deploy databases
echo "📊 Deploying databases..."
kubectl apply -f k8s/customer-db.yaml -n "$NAMESPACE"
kubectl apply -f k8s/order-db.yaml -n "$NAMESPACE"
kubectl apply -f k8s/product-db.yaml -n "$NAMESPACE"

# Deploy RabbitMQ
echo "🐰 Deploying RabbitMQ..."
kubectl apply -f k8s/rabbitmq.yaml -n "$NAMESPACE"

# Deploy ConfigMaps and Secrets
echo "⚙️  Deploying configuration..."
kubectl apply -f k8s/configmaps.yaml -n "$NAMESPACE"
kubectl apply -f k8s/secrets.yaml -n "$NAMESPACE"

# Deploy HPA for production
if [ "$ENVIRONMENT" = "production" ]; then
    echo "📈 Deploying HPA configurations..."
    kubectl apply -f k8s/hpa.yaml -n "$NAMESPACE"
fi

# Deploy monitoring for production
if [ "$ENVIRONMENT" = "production" ]; then
    echo "📊 Deploying monitoring..."
    kubectl apply -f k8s/monitoring.yaml -n "$NAMESPACE"
fi

# Wait for all deployments
echo "⏳ Waiting for all deployments to be ready..."
kubectl wait --for=condition=available --timeout=600s deployment --all -n "$NAMESPACE"

# Run health checks
run_health_checks "$NAMESPACE"

# Display deployment status
echo "📋 Deployment Status:"
echo "===================="
kubectl get pods -n "$NAMESPACE"
kubectl get services -n "$NAMESPACE"

echo "🎉 Deployment to $ENVIRONMENT completed successfully!"
echo "🌐 Access your application at the LoadBalancer IPs shown above"

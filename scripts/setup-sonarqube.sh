#!/bin/bash

# SonarQube Setup Script for DevSecOps Project
# This script sets up SonarQube server and configures quality gates

set -e

echo "🚀 Setting up SonarQube for DevSecOps Project..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed or not in PATH"
    exit 1
fi

# Check if we're connected to a cluster
if ! kubectl cluster-info &> /dev/null; then
    print_error "Not connected to a Kubernetes cluster"
    exit 1
fi

print_status "Deploying SonarQube to Kubernetes..."

# Apply SonarQube manifests
kubectl apply -f k8s/sonarqube.yaml

print_status "Waiting for SonarQube to be ready..."

# Wait for SonarQube to be ready
kubectl wait --for=condition=available --timeout=600s deployment/sonarqube -n sonarqube

print_status "SonarQube is ready!"

# Get SonarQube service details
SONARQUBE_IP=$(kubectl get service sonarqube -n sonarqube -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
SONARQUBE_PORT=$(kubectl get service sonarqube -n sonarqube -o jsonpath='{.spec.ports[0].port}')

if [ -z "$SONARQUBE_IP" ]; then
    print_warning "LoadBalancer IP not available. Using port-forward instead..."
    print_status "You can access SonarQube at: http://localhost:9000"
    print_status "Run: kubectl port-forward service/sonarqube 9000:9000 -n sonarqube"
else
    print_status "SonarQube is available at: http://$SONARQUBE_IP:$SONARQUBE_PORT"
fi

print_status "Setting up quality gates..."

# Create quality gate configuration
cat > /tmp/quality-gate.json << EOF
{
  "name": "DevSecOps Quality Gate",
  "conditions": [
    {
      "metric": "new_coverage",
      "op": "LT",
      "error": "80"
    },
    {
      "metric": "new_duplicated_lines_density",
      "op": "GT",
      "error": "3"
    },
    {
      "metric": "new_maintainability_rating",
      "op": "GT",
      "error": "1"
    },
    {
      "metric": "new_reliability_rating",
      "op": "GT",
      "error": "1"
    },
    {
      "metric": "new_security_rating",
      "op": "GT",
      "error": "1"
    },
    {
      "metric": "new_bugs",
      "op": "GT",
      "error": "0"
    },
    {
      "metric": "new_vulnerabilities",
      "op": "GT",
      "error": "0"
    },
    {
      "metric": "new_code_smells",
      "op": "GT",
      "error": "100"
    }
  ]
}
EOF

print_status "Quality gate configuration created at /tmp/quality-gate.json"

print_status "Setting up GitHub secrets configuration..."

cat > /tmp/github-secrets.md << EOF
# GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

## Required Secrets

1. **SONAR_TOKEN**: SonarQube authentication token
   - Generate in SonarQube: Administration > Security > Users > Tokens
   - Name: github-actions
   - Type: Global Analysis Token

2. **SONAR_HOST_URL**: SonarQube server URL
   - Value: http://$SONARQUBE_IP:$SONARQUBE_PORT (or http://localhost:9000 if using port-forward)

## How to add secrets:

1. Go to your GitHub repository
2. Navigate to Settings > Secrets and variables > Actions
3. Click "New repository secret"
4. Add each secret with the name and value above

## SonarQube Initial Setup:

1. Access SonarQube web interface
2. Login with default credentials: admin/admin
3. Change the default password
4. Create a new project for each service:
   - customer-service
   - order-service
   - product-service
   - frontend
5. Generate authentication tokens for each project
6. Configure quality gates as needed

## Project Configuration:

Each service has its own sonar-project.properties file:
- backend/customer_service/sonar-project.properties
- backend/order_service/sonar-project.properties
- backend/product_service/sonar-project.properties
- frontend/sonar-project.properties

## Quality Gate:

The quality gate enforces:
- Minimum 80% code coverage
- Maximum 3% duplicated lines
- No bugs or vulnerabilities
- Maintainability, reliability, and security ratings
- Maximum 100 code smells

EOF

print_status "GitHub secrets configuration saved to /tmp/github-secrets.md"

print_status "SonarQube setup complete! 🎉"

echo ""
echo "Next steps:"
echo "1. Access SonarQube web interface"
echo "2. Configure GitHub secrets as described in /tmp/github-secrets.md"
echo "3. Create projects in SonarQube for each service"
echo "4. Generate authentication tokens"
echo "5. Test the CI/CD pipeline with SonarQube integration"

if [ -z "$SONARQUBE_IP" ]; then
    echo ""
    echo "To access SonarQube, run:"
    echo "kubectl port-forward service/sonarqube 9000:9000 -n sonarqube"
    echo "Then open: http://localhost:9000"
fi

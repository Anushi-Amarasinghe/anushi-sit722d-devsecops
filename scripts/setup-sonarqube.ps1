# SonarQube Setup Script for DevSecOps Project
# This script sets up SonarQube server and configures quality gates

param(
    [switch]$SkipDeployment
)

Write-Host "🚀 Setting up SonarQube for DevSecOps Project..." -ForegroundColor Green

# Function to print colored output
function Write-Status {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Check if kubectl is available
try {
    kubectl version --client | Out-Null
} catch {
    Write-Error "kubectl is not installed or not in PATH"
    exit 1
}

# Check if we're connected to a cluster
try {
    kubectl cluster-info | Out-Null
} catch {
    Write-Error "Not connected to a Kubernetes cluster"
    exit 1
}

if (-not $SkipDeployment) {
    Write-Status "Deploying SonarQube to Kubernetes..."
    
    # Apply SonarQube manifests
    kubectl apply -f k8s/sonarqube.yaml
    
    Write-Status "Waiting for SonarQube to be ready..."
    
    # Wait for SonarQube to be ready
    kubectl wait --for=condition=available --timeout=600s deployment/sonarqube -n sonarqube
    
    Write-Status "SonarQube is ready!"
}

# Get SonarQube service details
$sonarqubeService = kubectl get service sonarqube -n sonarqube -o json | ConvertFrom-Json
$sonarqubeIP = $sonarqubeService.status.loadBalancer.ingress[0].ip
$sonarqubePort = $sonarqubeService.spec.ports[0].port

if ([string]::IsNullOrEmpty($sonarqubeIP)) {
    Write-Warning "LoadBalancer IP not available. Using port-forward instead..."
    Write-Status "You can access SonarQube at: http://localhost:9000"
    Write-Status "Run: kubectl port-forward service/sonarqube 9000:9000 -n sonarqube"
} else {
    Write-Status "SonarQube is available at: http://$sonarqubeIP`:$sonarqubePort"
}

Write-Status "Setting up quality gates..."

# Create quality gate configuration
$qualityGateConfig = @"
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
"@

$qualityGateConfig | Out-File -FilePath "quality-gate.json" -Encoding UTF8
Write-Status "Quality gate configuration created at quality-gate.json"

Write-Status "Setting up GitHub secrets configuration..."

$githubSecretsConfig = @"
# GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

## Required Secrets

1. **SONAR_TOKEN**: SonarQube authentication token
   - Generate in SonarQube: Administration > Security > Users > Tokens
   - Name: github-actions
   - Type: Global Analysis Token

2. **SONAR_HOST_URL**: SonarQube server URL
   - Value: http://$sonarqubeIP`:$sonarqubePort (or http://localhost:9000 if using port-forward)

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

## CI/CD Integration:

The pipeline now includes SonarQube scanning for:
- Code quality analysis
- Security vulnerability detection
- Code coverage reporting
- Quality gate enforcement
- PR decoration with analysis results

## Usage:

1. Push code to trigger the pipeline
2. SonarQube will analyze each service
3. Quality gates will be enforced
4. Results will be displayed in PRs
5. Failed quality gates will block deployment

"@

$githubSecretsConfig | Out-File -FilePath "github-secrets-config.md" -Encoding UTF8
Write-Status "GitHub secrets configuration saved to github-secrets-config.md"

Write-Status "SonarQube setup complete! 🎉"

Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "1. Access SonarQube web interface" -ForegroundColor White
Write-Host "2. Configure GitHub secrets as described in github-secrets-config.md" -ForegroundColor White
Write-Host "3. Create projects in SonarQube for each service" -ForegroundColor White
Write-Host "4. Generate authentication tokens" -ForegroundColor White
Write-Host "5. Test the CI/CD pipeline with SonarQube integration" -ForegroundColor White

if ([string]::IsNullOrEmpty($sonarqubeIP)) {
    Write-Host ""
    Write-Host "To access SonarQube, run:" -ForegroundColor Cyan
    Write-Host "kubectl port-forward service/sonarqube 9000:9000 -n sonarqube" -ForegroundColor White
    Write-Host "Then open: http://localhost:9000" -ForegroundColor White
}

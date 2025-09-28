# GitHub Secrets Configuration

Add the following secrets to your GitHub repository:

## Required Secrets

1. **SONAR_TOKEN**: SonarQube authentication token
   - Generate in SonarQube: Administration > Security > Users > Tokens
   - Name: github-actions
   - Type: Global Analysis Token

2. **SONAR_HOST_URL**: SonarQube server URL
   - Value: http://:9000 (or http://localhost:9000 if using port-forward)

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


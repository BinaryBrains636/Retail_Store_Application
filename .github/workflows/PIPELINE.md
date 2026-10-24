# Retail Store CI/CD Pipeline

This document describes the automated CI/CD pipeline for the Retail Store Application.

## Pipeline Stages

The pipeline consists of 8 stages that run sequentially:

### Stage 1: Lint and Validate
- **Purpose**: Validate code quality and configuration files
- **Actions**:
  - Lint all Dockerfiles using hadolint
  - Validate docker-compose.yaml syntax
  - Validate all Helm charts
- **Runs on**: Any push/PR to main or develop branches

### Stage 2: Build Docker Images
- **Purpose**: Build Docker images for all services
- **Actions**:
  - Build images for: ui, cart, catalog, checkout, orders, users
  - Generate image tags (branch, SHA, semver)
  - Save images as artifacts for later stages
- **Dependency**: Must pass lint stage
- **Runs on**: Any push/PR to main or develop branches

### Stage 3: Run Tests
- **Purpose**: Test Docker images
- **Actions**:
  - Load Docker images from artifacts
  - Run containers and perform health checks
  - Verify /actuator/health endpoint
- **Dependency**: Must pass build stage
- **Runs on**: Any push/PR to main or develop branches

### Stage 4: Security Scan
- **Purpose**: Scan images for vulnerabilities
- **Actions**:
  - Load Docker images from artifacts
  - Run Trivy vulnerability scanner
  - Upload results to GitHub Security
- **Dependency**: Must pass build stage
- **Runs on**: Any push/PR to main or develop branches

### Stage 5: Push to ECR
- **Purpose**: Push images to Amazon ECR
- **Actions**:
  - Configure AWS credentials
  - Login to Amazon ECR
  - Tag images with latest, branch name, and SHA
  - Push images to ECR
  - Update Helm chart values with new image tags
  - Commit updated Helm charts to repository
- **Dependency**: Must pass test and security-scan stages
- **Runs on**: Only on push to main branch

### Stage 6: Deploy to Staging
- **Purpose**: Deploy to staging environment
- **Actions**:
  - Configure AWS credentials
  - Update kubeconfig for staging EKS cluster
  - Deploy all services using Helm
  - Verify pod readiness
- **Dependency**: Must pass push stage
- **Environment**: staging
- **Runs on**: Only on push to main branch

### Stage 7: Deploy to Production
- **Purpose**: Deploy to production environment
- **Actions**:
  - Configure AWS credentials
  - Update kubeconfig for production EKS cluster
  - Deploy all services using Helm
  - Verify pod readiness
  - Run smoke tests
- **Dependency**: Must pass deploy-staging stage
- **Environment**: production
- **Runs on**: Only on push to main branch

### Stage 8: Notify
- **Purpose**: Send deployment notifications
- **Actions**:
  - Check deployment status
  - Send success/failure notifications
  - Can be configured for Slack, email, etc.
- **Dependency**: Always runs after deploy-production
- **Runs on**: Only on push to main branch

## Pipeline Triggers

The pipeline is triggered by:
- **Push to main branch**: Runs all stages
- **Push to develop branch**: Runs stages 1-4 (build and test only)
- **Pull Request to main**: Runs stages 1-4 (build and test only)
- **Pull Request to develop**: Runs stages 1-4 (build and test only)

## Required Secrets

Configure these secrets in your GitHub repository:

- `AWS_ACCESS_KEY_ID`: AWS access key with ECR and EKS permissions
- `AWS_SECRET_ACCESS_KEY`: AWS secret key
- `AWS_ACCOUNT_ID`: Your AWS account ID

## Environment Configuration

### Staging Environment
- EKS Cluster: `retail-store-staging`
- Namespace: `default`
- URL: https://staging.retail-store.com

### Production Environment
- EKS Cluster: `retail-store-production`
- Namespace: `production`
- URL: https://retail-store.com

## Matrix Build

Stages 2-4 use matrix builds to process all services in parallel:
- ui
- cart
- catalog
- checkout
- orders
- users

This allows faster pipeline execution by building and testing services concurrently.

## Failure Handling

- If any stage fails, subsequent stages are skipped
- Security scan failures are reported but don't block deployment (configurable)
- Deployment failures trigger notifications
- All artifacts are retained for 1 day

## Artifacts

- Docker images are saved as artifacts between stages
- Trivy scan results are uploaded to GitHub Security
- Artifacts are automatically cleaned up after 1 day

## Customization

To customize the pipeline:

1. **Add more linting rules**: Update the lint stage
2. **Add more tests**: Update the test stage
3. **Change deployment strategy**: Update deploy-staging and deploy-production stages
4. **Add notifications**: Configure Slack/webhook in the notify stage
5. **Change trigger branches**: Update the `on` section
6. **Add manual approval**: Add `environment` with `wait_for_approval`

## Manual Deployment

To deploy manually without the pipeline:

```bash
# Local deployment
cd 03_Docker_Files
./deploy-local.sh

# EKS deployment
cd 03_Docker_Files
./deploy-eks.sh

# ArgoCD deployment
cd 03_Docker_Files
./setup-argocd.sh
```

## Monitoring

Monitor pipeline execution:
- GitHub Actions tab in repository
- ArgoCD UI for GitOps deployments
- EKS console for cluster status
- CloudWatch for logs and metrics

## Rollback

If deployment fails:
```bash
# Rollback specific service
helm rollback retail-store-<service> -n <namespace>

# Rollback entire stack
cd 03_Docker_Files
# Run deploy-eks.sh with previous commit
```

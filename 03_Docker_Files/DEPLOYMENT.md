# Retail Store App - Deployment Guide

This guide explains how to deploy the Retail Store Application using different methods.

## Prerequisites

### For Local Deployment (Docker Compose)
- Docker installed and running
- Docker Compose installed

### For EKS Deployment
- kubectl configured with EKS cluster access
- Helm 3 installed
- AWS CLI configured

### For ArgoCD Deployment
- Kubernetes cluster (EKS or others)
- kubectl configured
- ArgoCD installed (or use setup script)

## Deployment Options

### Option 1: Local Deployment with Docker Compose

This is the easiest way to run the application locally for development.

```bash
cd 03_Docker_Files
./deploy-local.sh
```

Or manually:
```bash
cd 03_Docker_Files
docker-compose up -d --build
```

Access the application:
- UI: http://localhost:8080
- All services run on port 8080 internally

To stop:
```bash
docker-compose down
```

To view logs:
```bash
docker-compose logs -f
```

### Option 2: EKS Deployment with Helm

Deploy to EKS using Helm charts.

```bash
cd 03_Docker_Files
./deploy-eks.sh
```

Or manually for each service:
```bash
# Deploy cart service
helm upgrade --install retail-store-cart ./services/cart/chart \
  --namespace default \
  --values ./services/cart/chart/values.yaml

# Deploy catalog service
helm upgrade --install retail-store-catalog ./services/catalog/chart \
  --namespace default \
  --values ./services/catalog/chart/values.yaml

# Deploy checkout service
helm upgrade --install retail-store-checkout ./services/checkout/chart \
  --namespace default \
  --values ./services/checkout/chart/values.yaml

# Deploy orders service
helm upgrade --install retail-store-orders ./services/orders/chart \
  --namespace default \
  --values ./services/orders/chart/values.yaml

# Deploy users service
helm upgrade --install retail-store-users ./services/users/chart \
  --namespace default \
  --values ./services/users/chart/values.yaml

# Deploy UI service
helm upgrade --install retail-store-ui ./services/ui/chart \
  --namespace default \
  --values ./services/ui/chart/values.yaml
```

Get the UI service URL:
```bash
kubectl get svc -n default retail-store-ui
```

### Option 3: ArgoCD GitOps Deployment

Deploy using ArgoCD for GitOps-based continuous deployment.

#### Step 1: Setup ArgoCD

```bash
cd 03_Docker_Files
./setup-argocd.sh
```

#### Step 2: Access ArgoCD UI

```bash
# Port forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Open browser: https://localhost:8080

Get initial password:
```bash
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2
```

#### Step 3: Update Repository URL

Before deploying, update the ArgoCD manifests with your GitHub repository URL:

Edit files in `argocd-manifests/`:
- Update `repoURL` in `application-*.yaml` files
- Update `repoURL` in `applicationset.yaml`

Replace:
```yaml
repoURL: https://github.com/your-username/retail-store-app.git
```

With your actual repository URL.

#### Step 4: Deploy Applications

Deploy individual applications:
```bash
kubectl apply -f argocd-manifests/application-ui.yaml
kubectl apply -f argocd-manifests/application-cart.yaml
kubectl apply -f argocd-manifests/application-catalog.yaml
kubectl apply -f argocd-manifests/application-checkout.yaml
kubectl apply -f argocd-manifests/application-orders.yaml
kubectl apply -f argocd-manifests/application-users.yaml
```

Or deploy using ApplicationSet (recommended):
```bash
kubectl apply -f argocd-manifests/applicationset.yaml
```

## CI/CD with GitHub Actions

The repository includes a GitHub Actions workflow for building and pushing Docker images to AWS ECR.

### Setup Required Secrets

Add the following secrets to your GitHub repository:

- `AWS_ACCESS_KEY_ID`: AWS access key with ECR permissions
- `AWS_SECRET_ACCESS_KEY`: AWS secret key
- `AWS_ACCOUNT_ID`: Your AWS account ID

### Workflow Triggers

The workflow runs on:
- Push to `main` branch with changes in `03_Docker_Files/services/`
- Pull requests to `main` branch with changes in `03_Docker_Files/services/`

### What the Workflow Does

1. Checks out the code
2. Configures AWS credentials
3. Logs into Amazon ECR
3. Builds Docker images for all services (ui, cart, catalog, checkout, orders, users)
4. Pushes images to ECR
5. Tags images with branch name, SHA, and semantic version

## Services Overview

| Service | Port | Database | Purpose |
|---------|------|----------|---------|
| UI | 8080 | - | Frontend web application |
| Cart | 8080 | DynamoDB | Shopping cart management |
| Catalog | 8080 | MySQL | Product catalog |
| Checkout | 8080 | Redis | Checkout process |
| Orders | 8080 | PostgreSQL | Order management |
| Users | 8080 | PostgreSQL | User authentication |

## Troubleshooting

### Docker Compose Issues

If services fail to start:
```bash
# Check logs
docker-compose logs

# Restart specific service
docker-compose restart <service-name>

# Rebuild from scratch
docker-compose down -v
docker-compose up -d --build
```

### EKS/Helm Issues

If deployment fails:
```bash
# Check pod status
kubectl get pods -n default

# Check pod logs
kubectl logs -n default <pod-name>

# Describe pod for events
kubectl describe pod <pod-name> -n default

# Rollback release
helm rollback retail-store-<service> -n default
```

### ArgoCD Issues

If applications don't sync:
```bash
# Check application status
argocd app get <app-name>

# Force sync
argocd app sync <app-name>

# Check application logs
argocd app logs <app-name>
```

## Health Checks

Check service health:

### Docker Compose
```bash
docker-compose ps
```

### EKS
```bash
kubectl get pods -n default
kubectl get svc -n default
```

### ArgoCD
Check the ArgoCD UI or use CLI:
```bash
argocd app list
```

## Security Notes

- Update default passwords in production
- Use secrets management for sensitive data
- Enable RBAC in Kubernetes
- Use network policies to restrict traffic
- Enable pod security policies
- Scan images for vulnerabilities

## Production Considerations

For production deployment:
1. Use managed databases (RDS, ElastiCache, DynamoDB)
2. Enable SSL/TLS for all services
3. Implement proper logging and monitoring
4. Set up backup and disaster recovery
5. Use proper resource limits and requests
6. Enable horizontal pod autoscaling
7. Use ingress controller with proper TLS
8. Implement secrets management (AWS Secrets Manager, Sealed Secrets)
9. Enable security groups and network policies
10. Set up proper CI/CD with environment promotion

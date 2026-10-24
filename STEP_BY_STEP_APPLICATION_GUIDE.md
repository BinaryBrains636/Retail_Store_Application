
# Retail Store Application - Step-by-Step Execution Guide

This guide provides step-by-step instructions to run the Retail Store application using different methods.

---

## Table of Contents
1. [Method 1: Docker Compose (Local Development)](#method-1-docker-compose-local-development)
2. [Method 2: Kubernetes with ArgoCD (Production)](#method-2-kubernetes-with-argocd-production)
3. [Method 3: Helm Charts (Production)](#method-3-helm-charts-production)
4. [Testing the Application](#testing-the-application)
5. [Cleanup Instructions](#cleanup-instructions)

---

## Method 1: Docker Compose (Local Development)

### Prerequisites
- Docker Desktop installed
- 8GB RAM minimum
- Port 8888 available

### Step 1: Navigate to Project Directory
```bash
cd /Users/ishika/Desktop/Retail-store-app/01-Project-Files/Code-Backup-1.3.0/
```

### Step 2: Review Configuration Files
```bash
# View docker-compose.yaml
cat docker-compose.yaml

# View environment variables
cat .env
```

### Step 3: Start the Application
```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f
```

### Step 4: Verify Services are Running
```bash
# Check all containers
docker ps

# Check container health
docker-compose ps
```

### Step 5: Access the Application
- Open browser: http://localhost:8888
- You should see the Retail Store UI

### Step 6: Stop the Application
```bash
# Stop all services
docker-compose down

# Stop and remove volumes (clears data)
docker-compose down -v
```

---

## Method 2: Kubernetes with ArgoCD (Production)

### Prerequisites
- AWS EKS Cluster running
- kubectl configured
- ArgoCD installed on EKS
- AWS services provisioned (RDS, ElastiCache, DynamoDB, SQS)

### Step 1: Verify EKS Cluster Access
```bash
# Check cluster connection
kubectl get nodes

# Check cluster info
kubectl cluster-info
```

### Step 2: Install ArgoCD (if not already installed)
```bash
# Create argocd namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for ArgoCD pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
```

### Step 3: Access ArgoCD UI
```bash
# Port forward to access ArgoCD UI
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Open browser: https://localhost:8080
# Default username: admin
# Get initial password:
kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2
```

### Step 4: Prepare Kubernetes Manifests
```bash
# Navigate to manifests directory
cd /Users/ishika/Desktop/Retail-store-app/14_RetailStore_Microservices_with_AWS_Data_Plane/14_02_Microservices_with_AWS_Data_Plane/RetailStore_k8s_manifests_with_Data_Plane

# Review the directory structure
ls -la
```

### Step 5: Create ArgoCD Application
```bash
# Apply the ArgoCD application manifest
kubectl apply -f /Users/ishika/Desktop/Retail-store-app/argocd-retail-store-app.yaml

# Verify application creation
kubectl get application -n argocd
```

### Step 6: Sync Application in ArgoCD
1. Open ArgoCD UI at https://localhost:8080
2. Login with admin credentials
3. Click on the "retail-store" application
4. Click "Sync" button
5. Wait for sync to complete

### Step 7: Verify Deployment
```bash
# Check all pods
kubectl get pods -n default

# Check services
kubectl get svc -n default

# Check ingress
kubectl get ingress -n default
```

### Step 8: Access Application via Ingress
```bash
# Get ALB URL
kubectl get ingress retail-store-ingress -n default

# Access via the ALB URL provided
```

---

## Method 3: Helm Charts (Production)

### Prerequisites
- AWS EKS Cluster running
- kubectl configured
- Helm installed
- AWS services provisioned

### Step 1: Install Helm (if not installed)
```bash
# On macOS
brew install helm

# Verify installation
helm version
```

### Step 2: Navigate to Helm Charts Directory
```bash
cd /Users/ishika/Desktop/Retail-store-app/19_Helm_RetailStore_AWS_Dataplane/03_RetailStore_Helm_with_Data_Plane/01_retailstore_charts_updates/charts_v2.0.0
```

### Step 3: Review Helm Charts
```bash
# List available charts
ls -la

# Explore chart structure
cd retail-store-chart/
ls -la
```

### Step 4: Review Values File
```bash
# Navigate to values directory
cd /Users/ishika/Desktop/Retail-store-app/19_Helm_RetailStore_AWS_Dataplane/03_RetailStore_Helm_with_Data_Plane/02_retailstore_values_HELM_aws_dataplane

# View values file
cat values.yaml
```

### Step 5: Install Helm Chart
```bash
# Install the chart
helm install retail-store ./retail-store-chart -f values.yaml -n default

# Verify installation
helm list -n default
```

### Step 6: Verify Deployment
```bash
# Check pods
kubectl get pods -n default

# Check services
kubectl get svc -n default

# Check ingress
kubectl get ingress -n default
```

### Step 7: Access Application
```bash
# Get ingress URL
kubectl get ingress retail-store-ingress -n default

# Access via the URL
```

### Step 8: Upgrade Application (if needed)
```bash
# Update values file
vim values.yaml

# Upgrade release
helm upgrade retail-store ./retail-store-chart -f values.yaml -n default
```

### Step 9: Uninstall
```bash
# Uninstall the chart
helm uninstall retail-store -n default
```

---

## Testing the Application

### Test 1: Verify UI Access
```bash
# For Docker Compose
curl http://localhost:8888

# For Kubernetes/Ingress
curl http://<ALB-DNS-NAME>
```

### Test 2: Check Service Health
```bash
# Docker Compose
docker-compose ps

# Kubernetes
kubectl get pods -n default
kubectl describe pod <pod-name>
```

### Test 3: View Logs
```bash
# Docker Compose
docker-compose logs -f ui

# Kubernetes
kubectl logs -f deployment/ui -n default
```

### Test 4: Test API Endpoints
```bash
# Catalog Service
curl http://localhost:8888/api/products

# Cart Service
curl http://localhost:8888/api/cart

# Orders Service
curl http://localhost:8888/api/orders
```

### Test 5: Manual Browser Testing
1. Open http://localhost:8888 (or ALB URL)
2. Browse products in the catalog
3. Add items to cart
4. View cart contents
5. Place an order
6. Complete checkout process

---

## Cleanup Instructions

### Docker Compose Cleanup
```bash
cd /Users/ishika/Desktop/Retail-store-app/01-Project-Files/Code-Backup-1.3.0/

# Stop and remove containers
docker-compose down

# Stop and remove containers + volumes (clears all data)
docker-compose down -v

# Remove images (optional)
docker rmi $(docker images -q "retail-store-sample-*")
```

### Kubernetes Cleanup
```bash
# Delete ArgoCD application
kubectl delete application retail-store -n argocd

# Delete all resources in namespace
kubectl delete all --all -n default

# Delete ArgoCD (if needed)
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### Helm Cleanup
```bash
# Uninstall Helm release
helm uninstall retail-store -n default

# Verify cleanup
helm list -n default
kubectl get all -n default
```

---

## Troubleshooting

### Issue: Containers not starting
```bash
# Check logs
docker-compose logs

# Restart services
docker-compose restart
```

### Issue: Port 8888 already in use
```bash
# Find process using port
lsof -i :8888

# Kill process or change port in docker-compose.yaml
```

### Issue: Kubernetes pods in CrashLoopBackOff
```bash
# Check pod logs
kubectl logs <pod-name> -n default

# Describe pod for events
kubectl describe pod <pod-name> -n default
```

### Issue: ArgoCD sync failures
```bash
# Check ArgoCD application status
kubectl get application retail-store -n argocd -o yaml

# Check ArgoCD repository connection
# in ArgoCD UI: Settings > Repositories
```

---

## Architecture Overview

### Microservices
1. **UI Service** (Java Spring Boot) - Frontend interface
2. **Cart Service** (Java Spring Boot) - Shopping cart management
3. **Catalog Service** (Go) - Product catalog
4. **Orders Service** (Java Spring Boot) - Order processing
5. **Checkout Service** (Node.js) - Checkout workflow

### Data Stores
- **PostgreSQL** - Orders database
- **MySQL** - Catalog database
- **DynamoDB** - Cart storage
- **Redis** - Checkout cache
- **RabbitMQ** - Message queue

### Communication
- Services communicate via REST APIs
- RabbitMQ for asynchronous messaging
- ConfigMaps for configuration management

---

## Current Status

The application is currently running via Docker Compose with all containers healthy:

```
✅ UI Service: Running on port 8888
✅ Cart Service: Running
✅ Catalog Service: Running
✅ Orders Service: Running
✅ Checkout Service: Running
✅ PostgreSQL: Running
✅ MySQL: Running
✅ DynamoDB: Running
✅ Redis: Running
✅ RabbitMQ: Running
```

### Access Now
Open your browser and navigate to: **http://localhost:8888**

---

## Next Steps

1. **For Learning:** Try stopping the Docker Compose setup and deploying via Kubernetes
2. **For Production:** Use Kubernetes with ArgoCD or Helm charts
3. **For CI/CD:** Set up GitHub Actions to build and push to ECR, then use ArgoCD for deployment

---

## Additional Resources

- [Project README](../README.md)
- [Internship Task Schedule](../INTERNSHIP_TASK_SCHEDULE.md)
- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [ArgoCD Documentation](https://argoproj.github.io/cd/)
- [Helm Documentation](https://helm.sh/docs/)

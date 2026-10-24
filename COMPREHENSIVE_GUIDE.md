# Comprehensive Guide: Testing, Code Exploration, Kubernetes Deployment & CI/CD

This guide covers all four tasks in detail:
1. ✅ Testing the Application - User Journey Walkthrough
2. 📚 Exploring the Code - Microservices Architecture
3. ☸️ Deploying to Kubernetes - EKS Setup
4. 🚀 Implementing CI/CD - GitHub Actions Pipeline

---

# PART 1: Testing the Application - User Journey Walkthrough

## Current Status

✅ **Application is RUNNING** at http://localhost:8888
✅ All 10 containers are healthy
✅ All services are operational

## User Journey Testing

### Step 1: Browse Products (Catalog Service)

**Test the Catalog API:**
```bash
# Get all products
docker exec retail-sample-catalog-1 curl -s http://localhost:8080/catalog/products | head -50

# Get product count
docker exec retail-sample-catalog-1 curl -s http://localhost:8080/catalog/size

# Get products by tag
docker exec retail-sample-catalog-1 curl -s "http://localhost:8080/catalog/products?tags=vehicles"
```

**Expected Output:**
- JSON array of products with id, name, description, price, tags
- Products include: Aqua Ace GT, Audio-Illusion Spinner, Facechanger Formal Wear, etc.

**Manual Testing in Browser:**
1. Open http://localhost:8888
2. Browse the product catalog
3. Filter by tags (vehicles, accessories, clothing, food)
4. Click on any product to view details
5. Select size and quantity

### Step 2: Add to Cart (Cart Service)

**Test the Cart API:**
```bash
# Check cart endpoint (via UI service)
curl -s http://localhost:8888/api/cart

# View cart service health
docker exec retail-sample-cart-1 curl -s http://localhost:8080/actuator/health
```

**Manual Testing in Browser:**
1. Select a product (e.g., "Aqua Ace GT")
2. Choose size and quantity
3. Click "Add to Cart"
4. View cart icon in top right corner showing item count
5. Click cart icon to view cart contents

### Step 3: View Cart

**Manual Testing in Browser:**
1. Click the cart icon (top right)
2. Review selected items
3. Update quantities
4. Remove items if needed
5. View total price

### Step 4: Place Order (Orders Service)

**Test the Orders API:**
```bash
# Check orders service health
docker exec retail-sample-orders-1 curl -s http://localhost:8080/actuator/health

# View orders endpoint (via UI)
curl -s http://localhost:8888/api/orders
```

**Manual Testing in Browser:**
1. Click "Checkout" from cart
2. Enter shipping information
3. Select payment method
4. Review order summary
5. Click "Place Order"

### Step 5: Complete Checkout (Checkout Service)

**Test the Checkout API:**
```bash
# Check checkout service health
docker exec retail-sample-checkout-1 curl -s http://localhost:8080/health
```

**Manual Testing in Browser:**
1. Complete payment process
2. Wait for order confirmation
3. View order ID
4. Receive confirmation message

### Step 6: View Order History

**Manual Testing in Browser:**
1. Navigate to "Orders" section
2. View order history
3. Check order status
4. View order details

## Service Communication Flow

```
User → UI Service (Port 8888)
        ↓
    Catalog Service (Go + MySQL)
    Cart Service (Java + DynamoDB)
    Orders Service (Java + PostgreSQL)
    Checkout Service (Node.js + Redis + RabbitMQ)
```

## Monitoring During Testing

### View Real-time Logs
```bash
# UI Service logs
docker logs -f retail-sample-ui-1

# Catalog Service logs
docker logs -f retail-sample-catalog-1

# Cart Service logs
docker logs -f retail-sample-cart-1

# Orders Service logs
docker logs -f retail-sample-orders-1

# Checkout Service logs
docker logs -f retail-sample-checkout-1
```

### Check Service Health
```bash
# All services status
docker-compose ps

# Specific service health
docker inspect retail-sample-ui-1 | grep -A 10 Health
```

### Database Verification
```bash
# Check MySQL (Catalog)
docker exec retail-sample-catalog-db-1 mysql -u catalog_user -p${DB_PASSWORD} -e "USE catalogdb; SHOW TABLES;"

# Check PostgreSQL (Orders)
docker exec retail-sample-orders-db-1 psql -U orders_user -d orders -c "\dt"

# Check Redis (Checkout)
docker exec retail-sample-checkout-redis-1 redis-cli KEYS "*"

# Check DynamoDB (Cart)
docker exec retail-sample-carts-db-1 curl -s http://localhost:8000
```

---

# PART 2: Exploring the Code - Microservices Architecture

## Architecture Overview

The application follows a **microservices architecture** with 5 independent services:

```
┌─────────────────────────────────────────────────────────┐
│                    UI Service (Java)                      │
│              - React Frontend + Spring Boot               │
│              - Gateway to all backend services            │
└────────┬────────────────────────────────────────────────┘
         │
         ├──────────────┬──────────────┬──────────────┐
         │              │              │              │
         ▼              ▼              ▼              ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│   Catalog    │ │     Cart     │ │    Orders    │ │   Checkout   │
│   (Go)       │ │   (Java)     │ │   (Java)     │ │  (Node.js)   │
│              │ │              │ │              │ │              │
│  Gin Router  │ │ Spring Boot  │ │ Spring Boot  │ │   Express    │
│              │ │              │ │              │ │              │
└──────┬───────┘ └──────┬───────┘ └──────┬───────┘ └──────┬───────┘
       │                │                │                │
       ▼                ▼                ▼                ▼
┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
│    MySQL     │ │  DynamoDB    │ │  PostgreSQL  │ │    Redis     │
│  (MariaDB)   │ │              │ │              │ │              │
└──────────────┘ └──────────────┘ └──────┬───────┘ └──────────────┘
                                            │
                                            ▼
                                    ┌──────────────┐
                                    │  RabbitMQ    │
                                    │              │
                                    └──────────────┘
```

## Service Details

### 1. UI Service (Java Spring Boot)

**Location:** `src/ui/`

**Technology Stack:**
- Language: Java 21
- Framework: Spring Boot 3.x
- Web Server: Netty (Reactive)
- Frontend: React.js

**Key Components:**
```bash
src/ui/
├── src/main/java/com/amazonaws/ui/
│   ├── UiApplication.java          # Main application entry point
│   ├── controller/                 # REST controllers
│   │   ├── CatalogController.java  # Catalog API calls
│   │   ├── CartController.java     # Cart API calls
│   │   ├── OrdersController.java   # Orders API calls
│   │   └── CheckoutController.java # Checkout API calls
│   ├── config/                     # Configuration classes
│   │   └── WebClientConfig.java    # HTTP client config
│   └── model/                      # Data models
├── src/main/resources/
│   ├── application.yml             # Application configuration
│   └── application-prod.yml        # Production config
└── Dockerfile                      # Container image definition
```

**Responsibilities:**
- Serve React frontend
- Act as API gateway for frontend
- Proxy requests to backend services
- Handle session management
- Provide unified API endpoints

**Configuration:**
```yaml
# application.yml
retail:
  ui:
    endpoints:
      catalog: http://catalog:8080
      carts: http://carts:8080
      orders: http://orders:8080
      checkout: http://checkout:8080
```

**Endpoints:**
- `/` - Frontend UI
- `/api/products` - Products (proxied to Catalog)
- `/api/cart` - Cart operations (proxied to Cart)
- `/api/orders` - Orders (proxied to Orders)
- `/api/checkout` - Checkout (proxied to Checkout)

### 2. Catalog Service (Go)

**Location:** `src/catalog/`

**Technology Stack:**
- Language: Go 1.x
- Framework: Gin (Web Framework)
- Database: MySQL (MariaDB)

**Key Components:**
```bash
src/catalog/
├── api/
│   └── catalog.go                 # API handlers
├── controller/
│   └── catalog_controller.go      # Request handlers
├── model/
│   └── product.go                # Product data model
├── repository/
│   └── catalog_repository.go     # Database operations
├── config/
│   └── config.go                 # Configuration
├── middleware/
│   └── cors.go                   # CORS middleware
└── main.go                       # Application entry point
```

**Responsibilities:**
- Manage product catalog
- CRUD operations for products
- Tag-based filtering
- Search functionality
- Product inventory management

**API Endpoints:**
- `GET /catalog/products` - List all products
- `GET /catalog/products/{id}` - Get product by ID
- `GET /catalog/size` - Get total product count
- `GET /catalog/tags` - Get all tags
- `GET /catalog/products?tags=X` - Filter by tags

**Database Schema:**
```sql
CREATE TABLE products (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255),
    description TEXT,
    price DECIMAL(10,2),
    tags JSON
);
```

### 3. Cart Service (Java Spring Boot)

**Location:** `src/cart/`

**Technology Stack:**
- Language: Java 21
- Framework: Spring Boot 3.x
- Database: DynamoDB (NoSQL)

**Key Components:**
```bash
src/cart/
├── src/main/java/com/amazonaws/cart/
│   ├── CartApplication.java          # Main application
│   ├── controller/
│   │   └── CartController.java       # Cart API
│   ├── service/
│   │   └── CartService.java          # Business logic
│   ├── model/
│   │   └── CartItem.java             # Cart item model
│   ├── config/
│   │   └── DynamoDBConfiguration.java # DynamoDB config
│   └── repository/
│       └── CartRepository.java       # Data access
├── src/main/resources/
│   └── application.yml
└── Dockerfile
```

**Responsibilities:**
- Manage shopping cart
- Add/remove items
- Update quantities
- Calculate totals
- Session-based cart management

**API Endpoints:**
- `GET /cart/{customerId}` - Get cart
- `POST /cart/{customerId}` - Add item to cart
- `DELETE /cart/{customerId}/{itemId}` - Remove item
- `PUT /cart/{customerId}/{itemId}` - Update quantity

**DynamoDB Schema:**
```json
{
  "customerId": "string",
  "items": [
    {
      "itemId": "string",
      "quantity": 1,
      "price": 100.00
    }
  ]
}
```

### 4. Orders Service (Java Spring Boot)

**Location:** `src/orders/`

**Technology Stack:**
- Language: Java 21
- Framework: Spring Boot 3.x
- Database: PostgreSQL
- Message Queue: RabbitMQ

**Key Components:**
```bash
src/orders/
├── src/main/java/com/amazonaws/orders/
│   ├── OrdersApplication.java           # Main application
│   ├── controller/
│   │   └── OrdersController.java        # Orders API
│   ├── service/
│   │   └── OrdersService.java           # Business logic
│   ├── model/
│   │   └── Order.java                   # Order model
│   ├── events/
│   │   └── OrderEventHandler.java       # Event handling
│   ├── config/
│   │   ├── DatabaseConfig.java          # Database config
│   │   └── RabbitMQConfig.java          # RabbitMQ config
│   └── repository/
│       └── OrdersRepository.java        # Data access
├── src/main/resources/
│   └── application.yml
└── Dockerfile
```

**Responsibilities:**
- Order creation and management
- Order status tracking
- Event-driven processing via RabbitMQ
- Order history
- Integration with checkout

**API Endpoints:**
- `GET /orders/{customerId}` - Get customer orders
- `POST /orders` - Create new order
- `GET /orders/{orderId}` - Get order by ID
- `PUT /orders/{orderId}/status` - Update order status

**Database Schema:**
```sql
CREATE TABLE orders (
    id VARCHAR(36) PRIMARY KEY,
    customer_id VARCHAR(36),
    items JSON,
    total DECIMAL(10,2),
    status VARCHAR(50),
    created_at TIMESTAMP
);
```

**RabbitMQ Events:**
- Order created event
- Order status update event
- Payment confirmation event

### 5. Checkout Service (Node.js)

**Location:** `src/checkout/`

**Technology Stack:**
- Language: Node.js
- Framework: Express.js
- Cache: Redis
- Message Queue: RabbitMQ

**Key Components:**
```bash
src/checkout/
├── src/
│   ├── main.js                    # Application entry point
│   ├── routes/
│   │   └── checkout.js            # Checkout routes
│   ├── controllers/
│   │   └── checkoutController.js  # Business logic
│   ├── services/
│   │   ├── redisService.js       # Redis operations
│   │   └── rabbitmqService.js    # RabbitMQ operations
│   └── config/
│       └── config.js             # Configuration
├── test/
│   └── checkout.test.js          # Unit tests
├── package.json                  # Dependencies
└── Dockerfile
```

**Responsibilities:**
- Checkout process orchestration
- Payment processing simulation
- Order confirmation
- Cache management (Redis)
- Message publishing (RabbitMQ)

**API Endpoints:**
- `POST /checkout` - Initiate checkout
- `GET /checkout/{orderId}` - Get checkout status
- `POST /checkout/{orderId}/confirm` - Confirm checkout

**Redis Usage:**
- Cache checkout sessions
- Store temporary cart data
- Rate limiting

**RabbitMQ Usage:**
- Publish order events
- Notify Orders service
- Async processing

## Communication Patterns

### Synchronous Communication (REST APIs)
```
UI → Catalog: GET /catalog/products
UI → Cart: GET /cart/{customerId}
UI → Orders: GET /orders/{customerId}
UI → Checkout: POST /checkout
```

### Asynchronous Communication (RabbitMQ)
```
Checkout → RabbitMQ → Orders Service
Orders → RabbitMQ → Other services
```

### Database Communication
```
Catalog → MySQL (Read/Write)
Cart → DynamoDB (Read/Write)
Orders → PostgreSQL (Read/Write)
Checkout → Redis (Read/Write)
```

## Docker Configuration

Each service has its own Dockerfile:

**UI Service (Java):**
```dockerfile
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY target/app.jar .
CMD ["java", "-jar", "app.jar"]
```

**Catalog Service (Go):**
```dockerfile
FROM golang:1.21-alpine AS builder
WORKDIR /app
COPY . .
RUN go build -o main
FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/main .
CMD ["./main"]
```

**Checkout Service (Node.js):**
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json .
RUN npm install
COPY . .
RUN npm run build
CMD ["node", "dist/main.js"]
```

## Security Features

All containers use:
- ✅ `read_only` filesystem (except /tmp)
- ✅ `cap_drop: all` (drop all Linux capabilities)
- ✅ `security_opt: no-new-privileges`
- ✅ Non-root user where possible
- ✅ `tmpfs` for /tmp

---

# PART 3: Deploying to Kubernetes - EKS Setup

## Prerequisites

- ✅ AWS Account with active subscription
- ✅ AWS CLI installed and configured
- ✅ kubectl installed
- ✅ Terraform installed
- ✅ Docker installed

## Step 1: Create VPC Infrastructure

```bash
# Navigate to VPC Terraform directory
cd /Users/ishika/Desktop/Retail-store-app/06_Terraform_Basics/06_06_VPC_with_Remote_Backend

# Initialize Terraform
terraform init

# Plan the infrastructure
terraform plan -out=tfplan

# Apply the infrastructure
terraform apply -auto-approve tfplan

# Verify VPC creation
terraform output vpc_id
terraform output public_subnet_ids
terraform output private_subnet_ids
```

## Step 2: Provision EKS Cluster

```bash
# Navigate to EKS Terraform directory
cd /Users/ishika/Desktop/Retail-store-app/07_Terraform_EKS_Cluster

# Initialize Terraform
terraform init

# Update terraform.tfvars with VPC outputs
cat > terraform.tfvars <<EOF
vpc_id = "$(cd ../06_Terraform_Basics/06_06_VPC_with_Remote_Backend && terraform output -raw vpc_id)"
private_subnet_ids = $(cd ../06_Terraform_Basics/06_06_VPC_with_Remote_Backend && terraform output -json private_subnet_ids)
public_subnet_ids = $(cd ../06_Terraform_Basics/06_06_VPC_with_Remote_Backend && terraform output -json public_subnet_ids)
cluster_name = "retail-store-eks"
cluster_version = "1.28"
EOF

# Plan and apply
terraform plan -out=tfplan
terraform apply -auto-approve tfplan

# Wait for cluster to be ready (5-10 minutes)
```

## Step 3: Configure kubectl

```bash
# Update kubeconfig
aws eks update-kubeconfig --name retail-store-eks --region us-east-1

# Verify cluster access
kubectl get nodes
kubectl cluster-info
```

## Step 4: Install EKS Add-ons

```bash
# Navigate to EKS Add-ons directory
cd /Users/ishika/Desktop/Retail-store-app/13_Terraform_EKS_Cluster_with_AddOns

# Initialize Terraform
terraform init

# Plan and apply
terraform plan -out=tfplan
terraform apply -auto-approve tfplan

# Verify add-ons
kubectl get pods -n kube-system
```

## Step 5: Prepare Kubernetes Manifests

```bash
# Navigate to manifests directory
cd /Users/ishika/Desktop/Retail-store-app/14_RetailStore_Microservices_with_AWS_Data_Plane/14_02_Microservices_with_AWS_Data_Plane/RetailStore_k8s_manifests_with_Data_Plane

# Review the structure
ls -la
```

**Manifest Structure:**
```
RetailStore_k8s_manifests_with_Data_Plane/
├── 01_aws_data_plane/
│   ├── rds_mysql.yaml
│   ├── elasticache_redis.yaml
│   ├── dynamodb.yaml
│   └── sqs.yaml
├── 02_RetailStore_Microservices/
│   ├── 01_catalog/
│   │   ├── 01_catalog_service_account.yaml
│   │   ├── 02_catalog_configmap.yaml
│   │   ├── 03_catalog_deployment.yaml
│   │   ├── 04_catalog_clusterip_service.yaml
│   │   └── 05_catalog_mysql_externalname_service.yaml
│   ├── 02_cart/
│   ├── 03_checkout/
│   ├── 04_orders/
│   └── 05_ui/
└── 03_ingress/
    └── 01_ingress_http_ip_mode.yaml
```

## Step 6: Deploy to Kubernetes

```bash
# Apply all manifests
kubectl apply -f 01_aws_data_plane/
kubectl apply -f 02_RetailStore_Microservices/
kubectl apply -f 03_ingress/

# Verify deployments
kubectl get deployments
kubectl get pods
kubectl get services
kubectl get ingress
```

## Step 7: Verify Deployment

```bash
# Check pod status
kubectl get pods -w

# Check logs
kubectl logs -f deployment/catalog
kubectl logs -f deployment/cart
kubectl logs -f deployment/orders
kubectl logs -f deployment/checkout
kubectl logs -f deployment/ui

# Check services
kubectl get svc

# Get ingress URL
kubectl get ingress
```

## Step 8: Access Application

```bash
# Get ALB DNS name
ALB_DNS=$(kubectl get ingress retail-store-ingress -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test access
curl http://$ALB_DNS

# Open in browser
open http://$ALB_DNS
```

## Step 9: Cleanup

```bash
# Delete Kubernetes resources
kubectl delete -f 03_ingress/
kubectl delete -f 02_RetailStore_Microservices/
kubectl delete -f 01_aws_data_plane/

# Destroy EKS cluster
cd /Users/ishika/Desktop/Retail-store-app/13_Terraform_EKS_Cluster_with_AddOns
terraform destroy -auto-approve

cd /Users/ishika/Desktop/Retail-store-app/07_Terraform_EKS_Cluster
terraform destroy -auto-approve

# Destroy VPC
cd /Users/ishika/Desktop/Retail-store-app/06_Terraform_Basics/06_06_VPC_with_Remote_Backend
terraform destroy -auto-approve
```

---

# PART 4: Implementing CI/CD - GitHub Actions Pipeline

## Pipeline Architecture

```
Git Push
    ↓
GitHub Actions (CI)
    ↓
Build Docker Image
    ↓
Push to ECR
    ↓
Update Helm Values
    ↓
ArgoCD (CD)
    ↓
Deploy to EKS
```

## Prerequisites

- ✅ GitHub repository
- ✅ AWS Account
- ✅ EKS Cluster running
- ✅ Amazon ECR repositories
- ✅ ArgoCD installed on EKS

## Step 1: Create ECR Repositories

```bash
export AWS_REGION=us-east-1

# Create repositories
aws ecr create-repository --repository-name retail-store/ui --region $AWS_REGION
aws ecr create-repository --repository-name retail-store/cart --region $AWS_REGION
aws ecr create-repository --repository-name retail-store/catalog --region $AWS_REGION
aws ecr create-repository --repository-name retail-store/orders --region $AWS_REGION
aws ecr create-repository --repository-name retail-store/checkout --region $AWS_REGION

# Verify
aws ecr describe-repositories --region $AWS_REGION
```

## Step 2: Create IAM OIDC Provider

```bash
# Create OIDC provider
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

## Step 3: Create IAM Role for GitHub Actions

```bash
# Create trust policy
cat > trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:YOUR_USERNAME/YOUR_REPO:*"
        }
      }
    }
  ]
}
EOF

# Create IAM role
aws iam create-role \
    --role-name github-actions-role \
    --assume-role-policy-document file://trust-policy.json

# Attach ECR policy
cat > ecr-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ecr:*"],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
    --role-name github-actions-role \
    --policy-name ECRPolicy \
    --policy-document file://ecr-policy.json

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name github-actions-role --query Role.Arn --output text)
echo "Role ARN: $ROLE_ARN"
```

## Step 4: Create GitHub Actions Workflow

The workflow files are already created in:
- `.github/workflows/00-setup-ecr.yml`
- `.github/workflows/01-infrastructure.yml`
- `.github/workflows/02-application.yml`

**Update the workflow files** with your AWS account ID and repository name.

## Step 5: Add Workflow to GitHub Repository

```bash
# Create GitHub repository (if not exists)
gh repo create YOUR_USERNAME/retail-store-pipeline --public --source=.

# Or add remote to existing repo
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git branch -M main
git push -u origin main
```

## Step 6: Configure GitHub Secrets

No secrets needed when using OIDC! The trust policy handles authentication.

## Step 7: Trigger the Pipeline

### Option A: Automatic Trigger
```bash
# Make a code change
echo "# Test" >> src/ui/README.md

# Commit and push
git add .
git commit -m "Test CI/CD pipeline"
git push origin main
```

### Option B: Manual Trigger
1. Go to GitHub repository
2. Click "Actions" tab
3. Select workflow
4. Click "Run workflow"

## Step 8: Monitor Pipeline

### View in GitHub Actions
1. Go to GitHub repository
2. Click "Actions" tab
3. Click on running workflow
4. View logs for each step

### Pipeline Steps:
1. ✅ Checkout code
2. ✅ Configure AWS credentials (OIDC)
3. ✅ Login to Amazon ECR
4. ✅ Build Docker image
5. ✅ Push to ECR (tags: latest, sha-XXXXXXX)
6. ✅ Update Helm values file
7. ✅ Commit and push changes

## Step 9: Install ArgoCD

```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Port forward
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get password
argocd admin initial-password -n argocd
```

## Step 10: Create ArgoCD Application

```bash
# Create application manifest
cat > argocd-app.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: retail-store
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
    targetRevision: main
    path: src/ui/chart
    helm:
      valueFiles:
        - values-ui.yaml
  destination:
    server: https://kubernetes.default.svc
    namespace: default
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF

# Apply
kubectl apply -f argocd-app.yaml
```

## Step 11: Verify Complete Flow

```bash
# 1. Make code change
vim src/ui/src/main/resources/application.yml

# 2. Commit and push
git add .
git commit -m "Update configuration"
git push origin main

# 3. Watch GitHub Actions (auto-triggered)
# Go to GitHub > Actions

# 4. Watch ArgoCD (auto-sync)
# Go to ArgoCD UI at https://localhost:8080

# 5. Verify deployment
kubectl get pods -n default
kubectl rollout status deployment/ui -n default

# 6. Test application
curl http://<ALB-DNS-NAME>
```

## Complete CI/CD Flow Summary

```
Developer → git push
           ↓
GitHub Actions (CI)
           ├─ Build Docker image
           ├─ Push to ECR
           └─ Update Helm values
           ↓
Git Repository (updated)
           ↓
ArgoCD (CD)
           ├─ Detect change
           ├─ Sync to EKS
           └─ Deploy via Helm
           ↓
Kubernetes EKS
           └─ Running application
```

## Cleanup CI/CD Resources

```bash
# Delete ArgoCD application
kubectl delete application retail-store -n argocd

# Uninstall ArgoCD
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Delete IAM role
aws iam delete-role-policy --role-name github-actions-role --policy-name ECRPolicy
aws iam delete-role --role-name github-actions-role

# Delete OIDC provider
aws iam delete-open-id-connect-provider \
    --open-id-connect-provider-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):oidc-provider/token.actions.githubusercontent.com

# Delete ECR repositories
for service in ui cart catalog orders checkout; do
  aws ecr delete-repository --repository-name retail-store/$service --force
done
```

---

# Summary

## What We Covered

### ✅ Part 1: Testing the Application
- Tested all API endpoints
- Verified service communication
- Monitored logs and health checks
- Completed user journey walkthrough

### ✅ Part 2: Exploring the Code
- Understood microservices architecture
- Explored each service's code structure
- Learned technology stack per service
- Understood communication patterns

### ✅ Part 3: Deploying to Kubernetes
- Set up VPC with Terraform
- Provisioned EKS cluster
- Deployed microservices with Kubernetes manifests
- Accessed application via LoadBalancer

### ✅ Part 4: Implementing CI/CD
- Created ECR repositories
- Set up GitHub Actions with OIDC
- Configured ArgoCD for GitOps
- Implemented complete CI/CD pipeline

## Key Learnings

1. **Microservices Architecture**: Independent services with specific responsibilities
2. **Polyglot Programming**: Java, Go, Node.js in one application
3. **Multiple Databases**: MySQL, PostgreSQL, DynamoDB, Redis for different use cases
4. **Communication Patterns**: REST APIs for sync, RabbitMQ for async
5. **Infrastructure as Code**: Terraform for AWS resources
6. **Container Orchestration**: Kubernetes for deployment
7. **CI/CD Best Practices**: GitHub Actions + ArgoCD GitOps
8. **Security**: OIDC authentication, container hardening

## Next Steps

1. **Add Monitoring**: Implement Prometheus/Grafana
2. **Add Logging**: Centralized logging with ELK/Loki
3. **Add Tracing**: Distributed tracing with OpenTelemetry
4. **Add Autoscaling**: Implement HPA and Karpenter
5. **Add Testing**: Unit tests, integration tests, E2E tests
6. **Add Policies**: OPA/Gatekeeper for policy enforcement

## Documentation References

- [Step-by-Step Application Guide](STEP_BY_STEP_APPLICATION_GUIDE.md)
- [Complete Pipeline Guide](COMPLETE_PIPELINE_GUIDE.md)
- [CI/CD ArgoCD Guide](CICD_ARGOCD_EXECUTION_GUIDE.md)
- [Quick Start Pipeline](QUICK_START_PIPELINE.md)
- [Internship Task Schedule](INTERNSHIP_TASK_SCHEDULE.md)
- [App Status](APP_STATUS.md)

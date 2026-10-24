# Complete CI/CD Pipeline: Terraform + Docker + EKS + ECR

This guide creates a comprehensive pipeline that:
1. ✅ Runs Terraform scripts to provision EKS cluster
2. ✅ Builds Docker images for microservices
3. ✅ Pushes images to Amazon ECR
4. ✅ Deploys applications to EKS

---

## Architecture Overview

```
Git Push (Infrastructure Code)
        ↓
GitHub Actions (Infrastructure CI)
        ↓
Terraform Apply (Provision EKS)
        ↓
Git Push (Application Code)
        ↓
GitHub Actions (Application CI)
        ↓
Build Docker Images
        ↓
Push to ECR
        ↓
Deploy to EKS (kubectl or ArgoCD)
```

---

## Prerequisites

### Required Accounts & Services
- ✅ AWS Account with active subscription
- ✅ GitHub Account
- ✅ Terraform Cloud or State backend (S3 + DynamoDB)

### Required Tools
- AWS CLI installed and configured
- Terraform installed
- kubectl installed
- Docker installed

### IAM Permissions
- Full permissions for:
  - EC2 (VPC, subnets, NAT Gateway)
  - EKS (cluster, node groups)
  - IAM (roles, policies)
  - ECR (repositories, images)
  - S3 (Terraform state)
  - DynamoDB (state locking)

---

## Phase 1: Repository Structure Setup

### Step 1: Create Repository Structure
```bash
mkdir -p complete-pipeline
cd complete-pipeline

# Create directory structure
mkdir -p infrastructure/terraform
mkdir -p infrastructure/terraform/vpc
mkdir -p infrastructure/terraform/eks
mkdir -p infrastructure/terraform/eks-addons
mkdir -p applications/ui
mkdir -p applications/cart
mkdir -p applications/catalog
mkdir -p applications/orders
mkdir -p applications/checkout
mkdir -p .github/workflows
```

### Step 2: Copy Terraform Files
```bash
# Copy VPC Terraform
cp -r /Users/ishika/Desktop/Retail-store-app/06_Terraform_Basics/06_06_VPC_with_Remote_Backend/* \
   infrastructure/terraform/vpc/

# Copy EKS Terraform
cp -r /Users/ishika/Desktop/Retail-store-app/07_Terraform_EKS_Cluster/* \
   infrastructure/terraform/eks/

# Copy EKS Add-ons Terraform
cp -r /Users/ishika/Desktop/Retail-store-app/13_Terraform_EKS_Cluster_with_AddOns/* \
   infrastructure/terraform/eks-addons/
```

### Step 3: Copy Application Files
```bash
# Copy UI service
cp -r /Users/ishika/Desktop/Retail-store-app/21_DevOps_CICD/21_01_CI_github_actions_AWS_ECR/github-files/src/ui/* \
   applications/ui/

# Copy other services similarly
cp -r /Users/ishika/Desktop/Retail-store-app/21_DevOps_CICD/21_01_CI_github_actions_AWS_ECR/github-files/src/cart/* \
   applications/cart/

cp -r /Users/ishika/Desktop/Retail-store-app/21_DevOps_CICD/21_01_CI_github_actions_AWS_ECR/github-files/src/catalog/* \
   applications/catalog/

cp -r /Users/ishika/Desktop/Retail-store-app/21_DevOps_CICD/21_01_CI_github_actions_AWS_ECR/github-files/src/orders/* \
   applications/orders/

cp -r /Users/ishika/Desktop/Retail-store-app/21_DevOps_CICD/21_01_CI_github_actions_AWS_ECR/github-files/src/checkout/* \
   applications/checkout/
```

---

## Phase 2: Terraform State Backend Setup

### Step 1: Create S3 Bucket for Terraform State
```bash
export AWS_REGION=us-east-1
export BUCKET_NAME=terraform-state-retail-store-$(date +%s)

# Create S3 bucket
aws s3api create-bucket \
    --bucket $BUCKET_NAME \
    --region $AWS_REGION

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket $BUCKET_NAME \
    --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
    --bucket $BUCKET_NAME \
    --server-side-encryption-configuration \
    '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }'

echo "S3 Bucket: $BUCKET_NAME"
```

### Step 2: Create DynamoDB Table for State Locking
```bash
export TABLE_NAME=terraform-lock-retail-store

# Create DynamoDB table
aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $AWS_REGION

echo "DynamoDB Table: $TABLE_NAME"
```

### Step 3: Create Terraform Backend Configuration
```bash
cat > infrastructure/terraform/backend.tf <<EOF
terraform {
  backend "s3" {
    bucket         = "$BUCKET_NAME"
    key            = "retail-store/terraform.tfstate"
    region         = "$AWS_REGION"
    encrypt        = true
    dynamodb_table = "$TABLE_NAME"
  }
}
EOF
```

---

## Phase 3: GitHub Actions OIDC Setup

### Step 1: Create IAM OIDC Provider
```bash
# Create OIDC provider for GitHub
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Step 2: Create IAM Role for Infrastructure
```bash
cat > infra-trust-policy.json <<EOF
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
    --role-name github-actions-terraform-role \
    --assume-role-policy-document file://infra-trust-policy.json

# Attach AdministratorAccess (for simplicity - restrict in production)
aws iam attach-role-policy \
    --role-name github-actions-terraform-role \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Get role ARN
INFRA_ROLE_ARN=$(aws iam get-role --role-name github-actions-terraform-role --query Role.Arn --output text)
echo "Infrastructure Role ARN: $INFRA_ROLE_ARN"
```

### Step 3: Create IAM Role for Application
```bash
cat > app-trust-policy.json <<EOF
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
    --role-name github-actions-app-role \
    --assume-role-policy-document file://app-trust-policy.json

# Attach ECR and EKS policies
cat > app-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:*"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "eks:DescribeCluster",
        "eks:ListClusters"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
    --role-name github-actions-app-role \
    --policy-name AppDeployPolicy \
    --policy-document file://app-policy.json

# Get role ARN
APP_ROLE_ARN=$(aws iam get-role --role-name github-actions-app-role --query Role.Arn --output text)
echo "Application Role ARN: $APP_ROLE_ARN"
```

---

## Phase 4: Create GitHub Actions Workflows

### Step 1: Infrastructure Workflow (Terraform)
```bash
cat > .github/workflows/infrastructure.yml <<EOF
name: Infrastructure Provisioning

on:
  push:
    branches: [ "main" ]
    paths:
      - "infrastructure/terraform/**"
  workflow_dispatch:

permissions:
  id-token: write
  contents: write

env:
  AWS_REGION: us-east-1
  TF_VERSION: 1.5.0

jobs:
  terraform-apply:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: $INFRA_ROLE_ARN
          aws-region: \${{ env.AWS_REGION }}

      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: \${{ env.TF_VERSION }}

      - name: Terraform Init (VPC)
        run: |
          cd infrastructure/terraform/vpc
          terraform init

      - name: Terraform Plan (VPC)
        run: |
          cd infrastructure/terraform/vpc
          terraform plan -out=tfplan

      - name: Terraform Apply (VPC)
        run: |
          cd infrastructure/terraform/vpc
          terraform apply -auto-approve tfplan

      - name: Terraform Init (EKS)
        run: |
          cd infrastructure/terraform/eks
          terraform init

      - name: Terraform Plan (EKS)
        run: |
          cd infrastructure/terraform/eks
          terraform plan -out=tfplan

      - name: Terraform Apply (EKS)
        run: |
          cd infrastructure/terraform/eks
          terraform apply -auto-approve tfplan

      - name: Configure kubectl
        run: |
          aws eks update-kubeconfig --name retail-store-eks --region \${{ env.AWS_REGION }}

      - name: Terraform Init (EKS Add-ons)
        run: |
          cd infrastructure/terraform/eks-addons
          terraform init

      - name: Terraform Plan (EKS Add-ons)
        run: |
          cd infrastructure/terraform/eks-addons
          terraform plan -out=tfplan

      - name: Terraform Apply (EKS Add-ons)
        run: |
          cd infrastructure/terraform/eks-addons
          terraform apply -auto-approve tfplan

      - name: Verify EKS Cluster
        run: |
          kubectl get nodes
          kubectl get pods -n kube-system

      - name: Output EKS Details
        run: |
          echo "EKS Cluster provisioned successfully"
          kubectl cluster-info
EOF
```

### Step 2: Application Workflow (Docker + ECR + EKS)
```bash
cat > .github/workflows/application.yml <<EOF
name: Application Build and Deploy

on:
  push:
    branches: [ "main" ]
    paths:
      - "applications/**"
  workflow_dispatch:

permissions:
  id-token: write
  contents: write

env:
  AWS_REGION: us-east-1

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: [ui, cart, catalog, orders, checkout]

    steps:
      - name: Checkout code
        uses: actions/checkout@v4

      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: $APP_ROLE_ARN
          aws-region: \${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      - name: Define image tags
        id: vars
        run: |
          SHA_TAG=sha-\${GITHUB_SHA::7}
          IMAGE_BASE="\${{ steps.login-ecr.outputs.registry }}/retail-store/\${{ matrix.service }}"
          echo "IMAGE_BASE=$IMAGE_BASE" >> \$GITHUB_ENV
          echo "TAGS=latest $SHA_TAG" >> \$GITHUB_ENV

      - name: Build Docker image
        run: |
          cd applications/\${{ matrix.service }}
          docker build -t \$IMAGE_BASE:latest .

      - name: Push to ECR
        run: |
          for tag in \$TAGS; do
            docker tag \$IMAGE_BASE:latest \$IMAGE_BASE:\$tag
            docker push \$IMAGE_BASE:\$tag
          done

      - name: Configure kubectl
        run: |
          aws eks update-kubeconfig --name retail-store-eks --region \${{ env.AWS_REGION }}

      - name: Deploy to EKS
        run: |
          cd applications/\${{ matrix.service }}
          kubectl set image deployment/\${{ matrix.service }} \${{ matrix.service }}=\$IMAGE_BASE:sha-\${GITHUB_SHA::7} -n default

      - name: Verify deployment
        run: |
          kubectl rollout status deployment/\${{ matrix.service }} -n default
          kubectl get pods -l app=\${{ matrix.service }} -n default
EOF
```

### Step 3: ECR Repository Creation Workflow
```bash
cat > .github/workflows/setup-ecr.yml <<EOF
name: Setup ECR Repositories

on:
  workflow_dispatch:

permissions:
  id-token: write

env:
  AWS_REGION: us-east-1

jobs:
  create-repositories:
    runs-on: ubuntu-latest

    steps:
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: $APP_ROLE_ARN
          aws-region: \${{ env.AWS_REGION }}

      - name: Create ECR repositories
        run: |
          for service in ui cart catalog orders checkout; do
            aws ecr create-repository --repository-name retail-store/\$service --region \${{ env.AWS_REGION }} || true
          done

      - name: List repositories
        run: |
          aws ecr describe-repositories --region \${{ env.AWS_REGION }}
EOF
```

---

## Phase 5: Update Terraform Variables

### Step 1: Create terraform.tfvars for VPC
```bash
cat > infrastructure/terraform/vpc/terraform.tfvars <<EOF
vpc_cidr_block = "10.0.0.0/16"
public_subnet_cidr_blocks = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidr_blocks = ["10.0.3.0/24", "10.0.4.0/24"]
availability_zones = ["us-east-1a", "us-east-1b"]
environment = "production"
project_name = "retail-store"
EOF
```

### Step 2: Create terraform.tfvars for EKS
```bash
cat > infrastructure/terraform/eks/terraform.tfvars <<EOF
cluster_name = "retail-store-eks"
cluster_version = "1.28"
vpc_id = ""  # Will be output from VPC
private_subnet_ids = []  # Will be output from VPC
public_subnet_ids = []  # Will be output from VPC
node_group_name = "retail-store-nodes"
node_instance_types = ["t3.medium"]
desired_size = 2
max_size = 4
min_size = 1
EOF
```

---

## Phase 6: Initialize Git Repository

### Step 1: Initialize Git
```bash
cd complete-pipeline
git init
git add .
git commit -m "Initial commit: Infrastructure and application code"
```

### Step 2: Create GitHub Repository
```bash
# Create repository on GitHub (via UI or GitHub CLI)
gh repo create YOUR_USERNAME/retail-store-pipeline --public --source=.

# Or add remote manually
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git branch -M main
git push -u origin main
```

---

## Phase 7: Execute Pipeline

### Step 1: Create ECR Repositories
```bash
# Go to GitHub repository > Actions tab
# Select "Setup ECR Repositories" workflow
# Click "Run workflow"
# Wait for completion
```

### Step 2: Provision Infrastructure
```bash
# Push infrastructure code changes
git add infrastructure/terraform/
git commit -m "Update Terraform configuration"
git push origin main

# Or manually trigger:
# Go to GitHub > Actions > "Infrastructure Provisioning"
# Click "Run workflow"
# Wait for Terraform to complete (10-15 minutes)
```

### Step 3: Verify EKS Cluster
```bash
# After workflow completes, verify cluster
aws eks list-clusters --region us-east-1

# Update kubeconfig locally
aws eks update-kubeconfig --name retail-store-eks --region us-east-1

# Verify nodes
kubectl get nodes

# Verify system pods
kubectl get pods -n kube-system
```

### Step 4: Deploy Applications
```bash
# Push application code
git add applications/
git commit -m "Update application code"
git push origin main

# Or manually trigger:
# Go to GitHub > Actions > "Application Build and Deploy"
# Click "Run workflow"
# Wait for build and deployment (5-10 minutes)
```

### Step 5: Verify Deployments
```bash
# Check all deployments
kubectl get deployments -n default

# Check all pods
kubectl get pods -n default

# Check services
kubectl get svc -n default

# View logs
kubectl logs -f deployment/ui -n default
```

---

## Phase 8: Access Application

### Step 1: Create LoadBalancer Service
```bash
# Create LoadBalancer for UI
cat > ui-loadbalancer.yaml <<EOF
apiVersion: v1
kind: Service
metadata:
  name: ui-lb
  namespace: default
spec:
  type: LoadBalancer
  selector:
    app: ui
  ports:
    - port: 80
      targetPort: 8080
EOF

kubectl apply -f ui-loadbalancer.yaml
```

### Step 2: Get LoadBalancer URL
```bash
# Get LoadBalancer DNS
kubectl get svc ui-lb -n default

# Wait for DNS to be assigned
kubectl get svc ui-lb -n default -w
```

### Step 3: Access Application
```bash
# Get LoadBalancer URL
LB_URL=$(kubectl get svc ui-lb -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')

# Test access
curl http://$LB_URL

# Open in browser
open http://$LB_URL
```

---

## Monitoring the Pipeline

### GitHub Actions Dashboard
1. Go to your GitHub repository
2. Click on "Actions" tab
3. View running workflows
4. Click on workflow for detailed logs

### Terraform State
```bash
# View Terraform state
aws s3 ls s3://$BUCKET_NAME/

# Download state file
aws s3 cp s3://$BUCKET_NAME/retail-store/terraform.tfstate ./terraform.tfstate
```

### EKS Cluster Monitoring
```bash
# Watch nodes
kubectl get nodes -w

# Watch pods
kubectl get pods -n default -w

# Check events
kubectl get events -n default --sort-by='.lastTimestamp'
```

---

## Troubleshooting

### Terraform Issues

**Issue: State Lock Error**
```bash
# Check DynamoDB lock
aws dynamodb get-item \
    --table-name $TABLE_NAME \
    --key '{"LockID":{"S":"terraform-state-retail-store/terraform.tfstate-md5"}}'

# Force unlock (if necessary)
terraform force-unlock <LOCK_ID>
```

**Issue: EKS Cluster Creation Timeout**
```bash
# Check VPC outputs
cd infrastructure/terraform/vpc
terraform output

# Verify subnet configuration
aws ec2 describe-subnets --filters "Name=vpc-id,Values=<VPC_ID>"

# Check IAM roles
aws iam list-roles | grep retail-store
```

### Docker Build Issues

**Issue: Build Context Too Large**
```bash
# Add .dockerignore
cat > applications/ui/.dockerignore <<EOF
.git
README.md
*.md
.gitignore
node_modules
EOF
```

**Issue: Image Push Failed**
```bash
# Verify ECR repository
aws ecr describe-repositories --repository-names retail-store/ui

# Check ECR login
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.us-east-1.amazonaws.com
```

### Deployment Issues

**Issue: Pod ImagePullBackOff**
```bash
# Check pod events
kubectl describe pod <pod-name> -n default

# Verify image exists
aws ecr describe-images --repository-name retail-store/ui

# Check EKS node IAM role
aws iam get-instance-profile --instance-profile-name <NODE_INSTANCE_PROFILE>
```

**Issue: kubectl Configuration**
```bash
# Verify kubeconfig
kubectl config view

# Test cluster access
kubectl cluster-info

# Check current context
kubectl config current-context
```

---

## Cleanup

### Delete Applications
```bash
# Delete all deployments
kubectl delete deployments --all -n default
kubectl delete services --all -n default
```

### Destroy Infrastructure
```bash
# Delete EKS cluster
cd infrastructure/terraform/eks
terraform destroy -auto-approve

# Delete EKS add-ons
cd infrastructure/terraform/eks-addons
terraform destroy -auto-approve

# Delete VPC
cd infrastructure/terraform/vpc
terraform destroy -auto-approve
```

### Delete AWS Resources
```bash
# Delete ECR repositories
for service in ui cart catalog orders checkout; do
  aws ecr delete-repository --repository-name retail-store/$service --force --region us-east-1
done

# Delete S3 bucket
aws s3 rm s3://$BUCKET_NAME --recursive
aws s3api delete-bucket --bucket $BUCKET_NAME

# Delete DynamoDB table
aws dynamodb delete-table --table-name $TABLE_NAME

# Delete IAM roles
aws iam delete-role-policy --role-name github-actions-terraform-role --policy-name AdministratorAccess
aws iam delete-role --role-name github-actions-terraform-role

aws iam delete-role-policy --role-name github-actions-app-role --policy-name AppDeployPolicy
aws iam delete-role --role-name github-actions-app-role

# Delete OIDC provider
aws iam delete-open-id-connect-provider \
    --open-id-connect-provider-arn arn:aws:iam::$(aws sts get-caller-identity --query Account --output text):oidc-provider/token.actions.githubusercontent.com
```

---

## Summary

### Pipeline Stages

1. **Infrastructure Provisioning**
   - Trigger: Push to `infrastructure/terraform/**`
   - Action: Terraform apply
   - Output: EKS cluster, VPC, subnets, IAM roles

2. **Application Build & Deploy**
   - Trigger: Push to `applications/**`
   - Action: Build Docker → Push to ECR → Deploy to EKS
   - Output: Running microservices on EKS

3. **ECR Setup**
   - Trigger: Manual workflow_dispatch
   - Action: Create ECR repositories
   - Output: 5 ECR repositories

### Key Features

- ✅ **Infrastructure as Code:** Terraform manages all AWS resources
- ✅ **Automated Builds:** GitHub Actions builds and pushes images
- ✅ **Secure Access:** OIDC authentication (no access keys)
- ✅ **State Management:** S3 + DynamoDB for Terraform state
- ✅ **Multi-Service:** Parallel builds for all 5 microservices
- ✅ **Auto-Deploy:** Automatic deployment to EKS after build

### Workflow Triggers

- **Infrastructure:** Push to `infrastructure/terraform/**`
- **Application:** Push to `applications/**`
- **Manual:** Via GitHub Actions UI (workflow_dispatch)

---

## Next Steps

1. **Add ArgoCD:** Replace kubectl deployment with ArgoCD GitOps
2. **Add Tests:** Integrate automated testing in GitHub Actions
3. **Add Monitoring:** Integrate CloudWatch, Prometheus, Grafana
4. **Add Notifications:** Configure Slack/email alerts
5. **Add Policies:** Implement OPA/Gatekeeper for policy enforcement
6. **Add Multi-Environment:** Support dev/staging/production environments

---

## References

- [Terraform Documentation](https://developer.hashicorp.com/terraform/docs)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/AmazonECR/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)

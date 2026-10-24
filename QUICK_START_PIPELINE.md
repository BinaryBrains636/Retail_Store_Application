# Quick Start: Complete Pipeline Setup

This is a quick reference guide to set up the complete CI/CD pipeline.

---

## Prerequisites Checklist

- [ ] AWS Account with active subscription
- [ ] GitHub Account
- [ ] AWS CLI installed and configured
- [ ] Terraform installed
- [ ] kubectl installed
- [ ] Docker installed

---

## Step 1: AWS Setup (10 minutes)

### 1.1 Create S3 Bucket for Terraform State
```bash
export AWS_REGION=us-east-1
export BUCKET_NAME=terraform-state-retail-store-$(date +%s)

aws s3api create-bucket --bucket $BUCKET_NAME --region $AWS_REGION
aws s3api put-bucket-versioning --bucket $BUCKET_NAME --versioning-configuration Status=Enabled
```

### 1.2 Create DynamoDB Table for State Locking
```bash
export TABLE_NAME=terraform-lock-retail-store

aws dynamodb create-table \
    --table-name $TABLE_NAME \
    --attribute-definitions AttributeName=LockID,AttributeType=S \
    --key-schema AttributeName=LockID,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST \
    --region $AWS_REGION
```

### 1.3 Create OIDC Provider
```bash
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### 1.4 Create IAM Role for Infrastructure
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

aws iam create-role \
    --role-name github-actions-terraform-role \
    --assume-role-policy-document file://infra-trust-policy.json

aws iam attach-role-policy \
    --role-name github-actions-terraform-role \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

### 1.5 Create IAM Role for Application
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

aws iam create-role \
    --role-name github-actions-app-role \
    --assume-role-policy-document file://app-trust-policy.json

cat > app-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["ecr:*"],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": ["eks:DescribeCluster", "eks:ListClusters"],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
    --role-name github-actions-app-role \
    --policy-name AppDeployPolicy \
    --policy-document file://app-policy.json
```

### 1.6 Get Role ARNs
```bash
INFRA_ROLE_ARN=$(aws iam get-role --role-name github-actions-terraform-role --query Role.Arn --output text)
APP_ROLE_ARN=$(aws iam get-role --role-name github-actions-app-role --query Role.Arn --output text)

echo "Infrastructure Role: $INFRA_ROLE_ARN"
echo "Application Role: $APP_ROLE_ARN"
```

---

## Step 2: Repository Setup (5 minutes)

### 2.1 Create Repository Structure
```bash
mkdir -p complete-pipeline
cd complete-pipeline

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

### 2.2 Copy Files from Project
```bash
# Copy Terraform files
cp -r /Users/ishika/Desktop/Retail-store-app/06_Terraform_Basics/06_06_VPC_with_Remote_Backend/* \
   infrastructure/terraform/vpc/

cp -r /Users/ishika/Desktop/Retail-store-app/07_Terraform_EKS_Cluster/* \
   infrastructure/terraform/eks/

cp -r /Users/ishika/Desktop/Retail-store-app/13_Terraform_EKS_Cluster_with_AddOns/* \
   infrastructure/terraform/eks-addons/

# Copy application files
cp -r /Users/ishika/Desktop/Retail-store-app/21_DevOps_CICD/21_01_CI_github_actions_AWS_ECR/github-files/src/ui/* \
   applications/ui/

# Copy other services similarly...
```

### 2.3 Copy GitHub Actions Workflows
```bash
cp /Users/ishika/Desktop/Retail-store-app/.github/workflows/*.yml .github/workflows/
```

### 2.4 Update Workflow Files
Replace `YOUR_ACCOUNT_ID` in workflow files with your actual AWS account ID:
```bash
# Edit each workflow file
vim .github/workflows/01-infrastructure.yml
vim .github/workflows/02-application.yml
vim .github/workflows/00-setup-ecr.yml
```

### 2.5 Update Trust Policies
Replace `YOUR_USERNAME/YOUR_REPO` in trust policies with your actual GitHub repository:
```bash
# Update policies
vim infra-trust-policy.json
vim app-trust-policy.json

# Re-apply updated policies
aws iam delete-role --role-name github-actions-terraform-role
aws iam delete-role --role-name github-actions-app-role

# Re-create with updated policies
aws iam create-role \
    --role-name github-actions-terraform-role \
    --assume-role-policy-document file://infra-trust-policy.json

aws iam create-role \
    --role-name github-actions-app-role \
    --assume-role-policy-document file://app-trust-policy.json

# Re-attach policies
aws iam attach-role-policy \
    --role-name github-actions-terraform-role \
    --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

aws iam put-role-policy \
    --role-name github-actions-app-role \
    --policy-name AppDeployPolicy \
    --policy-document file://app-policy.json
```

### 2.6 Create Terraform Backend Config
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

### 2.7 Initialize Git
```bash
git init
git add .
git commit -m "Initial commit"
```

### 2.8 Create GitHub Repository
```bash
# Using GitHub CLI
gh repo create YOUR_USERNAME/retail-store-pipeline --public --source=.

# Or manually create on GitHub and add remote
git remote add origin https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
git branch -M main
git push -u origin main
```

---

## Step 3: Execute Pipeline (20-30 minutes)

### 3.1 Setup ECR Repositories
1. Go to GitHub repository
2. Click "Actions" tab
3. Select "Setup ECR Repositories"
4. Click "Run workflow"
5. Wait for completion (1-2 minutes)

### 3.2 Provision Infrastructure
1. Go to GitHub repository
2. Click "Actions" tab
3. Select "Infrastructure Provisioning"
4. Click "Run workflow"
5. Wait for completion (15-20 minutes)

### 3.3 Verify EKS Cluster
```bash
aws eks update-kubeconfig --name retail-store-eks --region us-east-1
kubectl get nodes
kubectl get pods -n kube-system
```

### 3.4 Deploy Applications
1. Make a change to application code
```bash
echo "# Test" >> applications/ui/README.md
git add .
git commit -m "Test application deployment"
git push origin main
```

2. Watch GitHub Actions "Application Build and Deploy" workflow
3. Wait for completion (5-10 minutes)

### 3.5 Verify Deployments
```bash
kubectl get deployments -n default
kubectl get pods -n default
kubectl get svc -n default
```

### 3.6 Access Application
```bash
# Create LoadBalancer service
cat > ui-lb.yaml <<EOF
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

kubectl apply -f ui-lb.yaml

# Get LoadBalancer URL
kubectl get svc ui-lb -n default
```

---

## Workflow Triggers

### Automatic Triggers
- **Infrastructure:** Push to `infrastructure/terraform/**`
- **Application:** Push to `applications/**`

### Manual Triggers
- **ECR Setup:** Actions > Setup ECR Repositories > Run workflow
- **Infrastructure:** Actions > Infrastructure Provisioning > Run workflow
- **Application:** Actions > Application Build and Deploy > Run workflow

---

## Cost Estimates

### AWS Resources (Monthly)
- EKS Cluster: ~$73
- EC2 Nodes (2x t3.medium): ~$60
- EBS Storage: ~$10
- Load Balancer: ~$20
- **Total: ~$160/month**

### GitHub Actions
- Free tier: 2000 minutes/month
- Paid: $0.008/minute

---

## Cleanup

### Delete Applications
```bash
kubectl delete all --all -n default
```

### Destroy Infrastructure
```bash
cd infrastructure/terraform/eks-addons
terraform destroy -auto-approve

cd infrastructure/terraform/eks
terraform destroy -auto-approve

cd infrastructure/terraform/vpc
terraform destroy -auto-approve
```

### Delete AWS Resources
```bash
# Delete ECR repositories
for service in ui cart catalog orders checkout; do
  aws ecr delete-repository --repository-name retail-store/$service --force
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

## Troubleshooting

### Workflow Fails - OIDC Error
```bash
# Verify trust policy matches your GitHub repo
aws iam get-role-policy --role-name github-actions-terraform-role --policy-name AssumeRolePolicy
```

### Terraform State Lock Error
```bash
# Check DynamoDB lock
aws dynamodb get-item \
    --table-name $TABLE_NAME \
    --key '{"LockID":{"S":"terraform-state-retail-store/terraform.tfstate-md5"}}'
```

### Image Pull Error
```bash
# Verify ECR repository
aws ecr describe-repositories --repository-names retail-store/ui

# Verify image exists
aws ecr describe-images --repository-name retail-store/ui
```

---

## Next Steps

1. ✅ **Complete Setup:** Follow the steps above
2. ✅ **Test Pipeline:** Make a code change and watch it deploy
3. ✅ **Add ArgoCD:** Replace kubectl deployment with GitOps
4. ✅ **Add Monitoring:** Integrate CloudWatch, Prometheus
5. ✅ **Add Tests:** Add automated testing in workflows

---

## Documentation

- [Complete Pipeline Guide](COMPLETE_PIPELINE_GUIDE.md) - Detailed instructions
- [CI/CD ArgoCD Guide](CICD_ARGOCD_EXECUTION_GUIDE.md) - ArgoCD integration
- [Step-by-Step Application Guide](STEP_BY_STEP_APPLICATION_GUIDE.md) - Application deployment methods
- [Internship Task Schedule](INTERNSHIP_TASK_SCHEDULE.md) - Learning roadmap

# GitHub Actions & ArgoCD Execution Guide

This guide provides step-by-step instructions to set up and execute the complete CI/CD pipeline using GitHub Actions and ArgoCD for the Retail Store application.

---

## Prerequisites

### Required Accounts & Services
- ✅ AWS Account with active subscription
- ✅ GitHub Account
- ✅ AWS EKS Cluster running
- ✅ Amazon ECR repository created
- ✅ ArgoCD installed on EKS cluster

### Required Tools
- AWS CLI installed and configured
- kubectl installed and configured
- Helm installed
- Git installed

### IAM Requirements
- IAM Role for GitHub Actions OIDC
- ECR permissions for pushing images
- EKS permissions for deployments

---

## Architecture Overview

```
Developer Push Code
        ↓
GitHub Actions (CI)
        ↓
Build Docker Image
        ↓
Push to Amazon ECR
        ↓
Update Helm Values in Git
        ↓
ArgoCD Detects Change (CD)
        ↓
Sync to Kubernetes EKS
        ↓
Application Deployed
```

---

## Phase 1: AWS Infrastructure Setup

### Step 1: Create ECR Repository
```bash
# Set your region
export AWS_REGION=us-east-1

# Create ECR repository for UI service
aws ecr create-repository \
    --repository-name retail-store/ui \
    --region $AWS_REGION

# Create repositories for other services
aws ecr create-repository --repository-name retail-store/cart --region $AWS_REGION
aws ecr create-repository --repository-name retail-store/catalog --region $AWS_REGION
aws ecr create-repository --repository-name retail-store/orders --region $AWS_REGION
aws ecr create-repository --repository-name retail-store/checkout --region $AWS_REGION

# List repositories
aws ecr describe-repositories --region $AWS_REGION
```

### Step 2: Create IAM OIDC Provider for GitHub Actions
```bash
# Get your EKS cluster OIDC provider URL
CLUSTER_NAME=your-eks-cluster-name
OIDC_PROVIDER=$(aws eks describe-cluster \
    --name $CLUSTER_NAME \
    --query "cluster.identity.oidc.issuer" \
    --output text \
    --region $AWS_REGION)

echo "OIDC Provider: $OIDC_PROVIDER"

# Create IAM OIDC provider for GitHub
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

### Step 3: Create IAM Role for GitHub Actions
```bash
# Create trust policy file
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
          "token.actions.githubusercontent.com:sub": "repo:YOUR_GITHUB_USERNAME/YOUR_REPO_NAME:*"
        }
      }
    }
  ]
}
EOF

# Create IAM role
aws iam create-role \
    --role-name github-actions-oidc-role \
    --assume-role-policy-document file://trust-policy.json

# Attach ECR policy
cat > ecr-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload",
        "ecr:SetRepositoryPolicy"
      ],
      "Resource": "arn:aws:ecr:$(aws sts get-caller-identity --query Account --output text):repository/retail-store/*"
    },
    {
      "Effect": "Allow",
      "Action": "ecr:GetAuthorizationToken",
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
    --role-name github-actions-oidc-role \
    --policy-name ECRPushPolicy \
    --policy-document file://ecr-policy.json

# Get role ARN
ROLE_ARN=$(aws iam get-role --role-name github-actions-oidc-role --query Role.Arn --output text)
echo "IAM Role ARN: $ROLE_ARN"
```

---

## Phase 2: GitHub Repository Setup

### Step 1: Fork or Create Repository
```bash
# Fork the course repository to your GitHub account
# OR create a new repository and copy the source code

# Clone your repository
git clone https://github.com/YOUR_USERNAME/YOUR_REPO_NAME.git
cd YOUR_REPO_NAME
```

### Step 2: Configure GitHub Actions Workflow
```bash
# Create .github/workflows directory
mkdir -p .github/workflows

# Copy the workflow file
cp /Users/ishika/Desktop/Retail-store-app/21_DevOps_CICD/21_01_CI_github_actions_AWS_ECR/github-files/.github/workflows/build-push-ui.yaml \
   .github/workflows/build-push-ui.yaml
```

### Step 3: Update Workflow Configuration
```bash
# Edit the workflow file with your settings
vim .github/workflows/build-push-ui.yaml
```

Update these values:
```yaml
env:
  AWS_REGION: us-east-1  # Your AWS region
  ECR_REPOSITORY: retail-store/ui  # Your ECR repository name

# In the OIDC step:
role-to-assume: arn:aws:iam::YOUR_ACCOUNT_ID:role/github-actions-oidc-role
```

### Step 4: Commit and Push
```bash
git add .github/workflows/build-push-ui.yaml
git commit -m "Add GitHub Actions workflow for CI"
git push origin main
```

---

## Phase 3: ArgoCD Installation

### Step 1: Install ArgoCD on EKS
```bash
# Create namespace
kubectl create namespace argocd

# Install ArgoCD
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods to be ready
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s

# Verify installation
kubectl get pods -n argocd
```

### Step 2: Access ArgoCD UI
```bash
# Port forward to access ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# In a new terminal, get the initial password
argocd admin initial-password -n argocd

# Open browser: https://localhost:8080
# Username: admin
# Password: (from command above)
```

### Step 3: Change ArgoCD Password
```bash
# After first login, change password via CLI
argocd account update-password

# Or via UI: User Settings > Change Password
```

---

## Phase 4: Prepare Application for ArgoCD

### Step 1: Copy Helm Charts to Repository
```bash
# Navigate to your repository
cd YOUR_REPO_NAME

# Create chart directory structure
mkdir -p src/ui/chart/templates

# Copy Helm chart files
cp -r /Users/ishika/Desktop/Retail-store-app/21_DevOps_CICD/21_01_CI_github_actions_AWS_ECR/github-files/src/ui/chart/* \
   src/ui/chart/

# Copy Dockerfile
cp /Users/ishika/Desktop/Retail-store-app/21_DevOps_CICD/21_01_CI_github_actions_AWS_ECR/github-files/src/ui/Dockerfile \
   src/ui/

# Copy application source code
cp -r /Users/ishika/Desktop/Retail-store-app/21_DevOps_CICD/21_01_CI_github_actions_AWS_ECR/github-files/src/ui/src \
   src/ui/
```

### Step 2: Update Helm Values
```bash
# Edit values file
vim src/ui/chart/values-ui.yaml
```

Update with your ECR repository:
```yaml
image:
  repository: YOUR_ACCOUNT_ID.dkr.ecr.us-east-1.amazonaws.com/retail-store/ui
  tag: sha-INITIAL
  pullPolicy: Always

service:
  type: ClusterIP
  port: 8080

ingress:
  enabled: true
  className: alb
  annotations:
    alb.ingress.kubernetes.io/scheme: internet-facing
  hosts:
    - host: retail-store.example.com
      paths:
        - path: /
          pathType: Prefix
```

### Step 3: Commit Helm Charts
```bash
git add src/ui/
git commit -m "Add Helm chart for UI service"
git push origin main
```

---

## Phase 5: Create ArgoCD Application

### Step 1: Create Application Manifest
```bash
# Create argocd-apps directory
mkdir -p argocd-apps

# Create application manifest
cat > argocd-apps/ui-application.yaml <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ui
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
```

### Step 2: Apply ArgoCD Application
```bash
# Apply the application manifest
kubectl apply -f argocd-apps/ui-application.yaml

# Verify application creation
kubectl get application -n argocd
```

### Step 3: Sync Application in ArgoCD UI
1. Open ArgoCD UI at https://localhost:8080
2. Click on the "ui" application
3. Click "Sync" button
4. Review changes and click "Synchronize"
5. Wait for sync to complete

---

## Phase 6: Trigger GitHub Actions (CI)

### Step 1: Make a Code Change
```bash
# Make a small change to trigger the workflow
echo "# Test change" >> src/ui/README.md

# Commit and push
git add src/ui/README.md
git commit -m "Test trigger GitHub Actions"
git push origin main
```

### Step 2: Monitor GitHub Actions
1. Go to your GitHub repository
2. Click on "Actions" tab
3. Click on the running workflow
4. Monitor the build process

### Step 3: Verify GitHub Actions Steps
The workflow should:
1. ✅ Checkout code
2. ✅ Configure AWS credentials via OIDC
3. ✅ Login to Amazon ECR
4. ✅ Build Docker image
5. ✅ Push image to ECR with tags (latest and sha-XXXXXXX)
6. ✅ Update Helm values file with new image tag
7. ✅ Commit and push the updated values file

---

## Phase 7: ArgoCD Auto-Sync (CD)

### Step 1: ArgoCD Detects Change
After GitHub Actions updates the Helm values file, ArgoCD will automatically detect the change because:
- Auto-sync is enabled
- Self-heal is enabled
- Git repository is being watched

### Step 2: Monitor ArgoCD Sync
1. Open ArgoCD UI
2. Click on the "ui" application
3. Watch the "Sync Status" change to "Synced"
4. Click on the sync to see details

### Step 3: Verify Deployment
```bash
# Check pods
kubectl get pods -n default

# Check deployment
kubectl get deployment ui -n default

# Check service
kubectl get svc ui -n default

# Check ingress
kubectl get ingress -n default

# View pod logs
kubectl logs -f deployment/ui -n default
```

---

## Phase 8: Access Deployed Application

### Step 1: Get Ingress URL
```bash
# Get ALB DNS name
kubectl get ingress ui -n default -o jsonpath='{.status.loadBalancer.ingress[0].hostname}'

# Or get full ingress details
kubectl describe ingress ui -n default
```

### Step 2: Access Application
```bash
# Access via ALB URL
curl http://<ALB-DNS-NAME>

# Or open in browser
open http://<ALB-DNS-NAME>
```

---

## Complete CI/CD Flow Verification

### Test the Complete Pipeline
```bash
# 1. Make a code change
vim src/ui/src/main/resources/application.yml

# 2. Commit and push
git add .
git commit -m "Update application configuration"
git push origin main

# 3. Watch GitHub Actions execute
# Go to GitHub > Actions tab

# 4. Watch ArgoCD auto-sync
# Go to ArgoCD UI

# 5. Verify deployment
kubectl get pods -n default
kubectl rollout status deployment/ui -n default

# 6. Test application
curl http://<ALB-DNS-NAME>/api/products
```

---

## Troubleshooting

### GitHub Actions Fails

**Issue: OIDC Authentication Error**
```bash
# Verify IAM role trust policy
aws iam get-role-policy --role-name github-actions-oidc-role --policy-name ECRPushPolicy

# Check GitHub Actions logs for specific error
# Verify repo name in trust policy matches your actual repo
```

**Issue: ECR Push Failed**
```bash
# Verify ECR repository exists
aws ecr describe-repositories --repository-names retail-store/ui

# Check IAM permissions
aws iam simulate-principal-policy \
    --policy-source-arn $ROLE_ARN \
    --action-names ecr:PutImage ecr:InitiateLayerUpload
```

### ArgoCD Sync Fails

**Issue: Application Not Syncing**
```bash
# Check ArgoCD application status
kubectl get application ui -n argocd -o yaml

# Check ArgoCD server logs
kubectl logs -n argocd deployment/argocd-server

# Manually trigger sync
argocd app sync ui
```

**Issue: Helm Chart Errors**
```bash
# Test Helm chart locally
helm template ui src/ui/chart -f src/ui/chart/values-ui.yaml

# Check Kubernetes events
kubectl get events -n default --sort-by='.lastTimestamp'
```

### Deployment Issues

**Issue: Pod Not Starting**
```bash
# Check pod status
kubectl describe pod <pod-name> -n default

# View pod logs
kubectl logs <pod-name> -n default

# Check image pull
kubectl describe pod <pod-name> -n default | grep -A 5 Events
```

**Issue: Image Pull Error**
```bash
# Verify image exists in ECR
aws ecr describe-images --repository-name retail-store/ui

# Check if tag matches Helm values
kubectl get deployment ui -n default -o yaml | grep image:
```

---

## Cleanup

### Remove ArgoCD Application
```bash
# Delete application
kubectl delete application ui -n argocd

# Delete deployed resources
kubectl delete all -l app=ui -n default
```

### Remove GitHub Actions Workflow
```bash
# Delete workflow file
rm .github/workflows/build-push-ui.yaml
git add .github/workflows/build-push-ui.yaml
git commit -m "Remove GitHub Actions workflow"
git push origin main
```

### Delete IAM Role
```bash
# Detach policies
aws iam delete-role-policy --role-name github-actions-oidc-role --policy-name ECRPushPolicy

# Delete role
aws iam delete-role --role-name github-actions-oidc-role

# Delete OIDC provider
aws iam delete-open-id-connect-provider \
    --open-id-connect-provider-arn arn:aws:iam::YOUR_ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com
```

### Delete ECR Repository
```bash
# Delete repository
aws ecr delete-repository --repository-name retail-store/ui --force --region $AWS_REGION
```

### Uninstall ArgoCD
```bash
kubectl delete -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl delete namespace argocd
```

---

## Summary

### CI/CD Pipeline Stages

1. **Developer commits code** → GitHub repository
2. **GitHub Actions triggers** → CI pipeline starts
3. **Build Docker image** → Using Dockerfile
4. **Push to ECR** → With OIDC authentication (no access keys)
5. **Update Helm values** → Auto-commit new image tag
6. **ArgoCD detects change** → Git polling
7. **Auto-sync to EKS** → Using Helm chart
8. **Application deployed** → Rolling update

### Key Benefits

- ✅ **No Access Keys:** OIDC authentication eliminates credential management
- ✅ **Automated:** Complete automation from commit to deployment
- ✅ **GitOps:** Desired state defined in Git
- ✅ **Self-Healing:** ArgoCD automatically fixes drift
- ✅ **Rollback:** Easy rollback via Git revert
- ✅ **Audit Trail:** Complete history in Git

---

## Next Steps

1. **Add More Services:** Create workflows for cart, catalog, orders, checkout
2. **Add Tests:** Integrate automated testing in GitHub Actions
3. **Add Notifications:** Configure Slack/email notifications
4. **Add Monitoring:** Integrate Prometheus/Grafana
5. **Add Policies:** Implement policy-as-code with OPA/Gatekeeper

---

## References

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [ArgoCD Documentation](https://argoproj.github.io/cd/)
- [AWS ECR Documentation](https://docs.aws.amazon.com/AmazonECR/)
- [AWS IAM OIDC](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_roles_create_for-idp_oidc.html)
- [Helm Documentation](https://helm.sh/docs/)

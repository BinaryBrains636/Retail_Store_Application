# GitHub Secrets and IAM Setup Guide

This guide will help you set up the required GitHub secrets and IAM roles for the CI/CD pipeline.

## Required GitHub Secrets

Configure these secrets in your GitHub repository:
- **AWS_ACCOUNT_ID**: Your AWS account ID (12-digit number)
- **AWS_ACCESS_KEY_ID**: AWS access key with ECR and EKS permissions
- **AWS_SECRET_ACCESS_KEY**: AWS secret key

## Setup Steps

### Step 1: Get Your AWS Account ID

```bash
aws sts get-caller-identity --query Account --output text
```

### Step 2: Create IAM Role for GitHub Actions (OIDC - Recommended)

Using OIDC is more secure than using access keys directly.

#### 2.1 Create IAM OIDC Provider

```bash
# Create IAM OIDC provider for GitHub
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1
```

#### 2.2 Create IAM Role for ECR

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
          "token.actions.githubusercontent.com:sub": "repo:BinaryBrains636/Retail_Store_Application:*"
        }
      }
    }
  ]
}
EOF

# Create the role
aws iam create-role \
    --role-name github-actions-app-role \
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
        "ecr:SetRepositoryPolicy",
        "ecr:DescribeRepositories"
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
    --role-name github-actions-app-role \
    --policy-name ECRPushPolicy \
    --policy-document file://ecr-policy.json

# Get role ARN
aws iam get-role --role-name github-actions-app-role --query Role.Arn --output text
```

#### 2.3 Create IAM Role for Terraform

```bash
# Create trust policy for Terraform role
cat > trust-policy-terraform.json <<EOF
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
          "token.actions.githubusercontent.com:sub": "repo:BinaryBrains636/Retail_Store_Application:*"
        }
      }
    }
  ]
}
EOF

# Create the role
aws iam create-role \
    --role-name github-actions-terraform-role \
    --assume-role-policy-document file://trust-policy-terraform.json

# Attach policies for Terraform (VPC, EKS, ECR)
cat > terraform-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:*",
        "eks:*",
        "iam:*",
        "ecr:*",
        "vpc:*",
        "route53:*",
        "elasticloadbalancing:*"
      ],
      "Resource": "*"
    }
  ]
}
EOF

aws iam put-role-policy \
    --role-name github-actions-terraform-role \
    --policy-name TerraformFullAccess \
    --policy-document file://terraform-policy.json

# Get role ARN
aws iam get-role --role-name github-actions-terraform-role --query Role.Arn --output text
```

### Step 3: Add Secrets to GitHub

Go to your GitHub repository settings:
1. Navigate to: Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Add the following secrets:

#### Using OIDC (Recommended):
- **AWS_ACCOUNT_ID**: Your AWS account ID (from Step 1)
- **AWS_REGION**: `us-east-1` (or your preferred region)

#### Using Access Keys (Alternative):
- **AWS_ACCESS_KEY_ID**: Your AWS access key
- **AWS_SECRET_ACCESS_KEY**: Your AWS secret key
- **AWS_ACCOUNT_ID**: Your AWS account ID
- **AWS_REGION**: `us-east-1` (or your preferred region)

### Step 4: Update Workflow Files with Role ARNs

If using OIDC, the workflows are already configured to use the role ARNs. The role ARNs are:
- App role: `arn:aws:iam::YOUR_ACCOUNT_ID:role/github-actions-app-role`
- Terraform role: `arn:aws:iam::YOUR_ACCOUNT_ID:role/github-actions-terraform-role`

Replace `YOUR_ACCOUNT_ID` with your actual AWS account ID in the workflow files, or the workflow will use the `AWS_ACCOUNT_ID` secret.

## Verification

### Verify IAM Role
```bash
aws iam get-role --role-name github-actions-app-role
aws iam get-role --role-name github-actions-terraform-role
```

### Verify OIDC Provider
```bash
aws iam list-open-id-connect-providers
```

## Quick Start with Access Keys (For Testing)

If you want to test quickly without OIDC setup:

1. Create an IAM user with AdministratorAccess (or more restrictive for production)
2. Create access keys for that user
3. Add the access keys as GitHub secrets
4. Update workflows to use access keys instead of OIDC

The current workflows are configured to use access keys by default in some places. To use OIDC, update the workflow files to remove the access key parameters and use only the role-to-assume parameter.

## Next Steps

After setting up secrets:

1. Run the "Setup ECR Repositories" workflow manually to create ECR repositories
2. Run the "Infrastructure Provisioning" workflow to create VPC and EKS
3. Make a code change to trigger the application build and deploy workflow
4. Monitor the pipeline in GitHub Actions
5. Check ArgoCD for deployment status

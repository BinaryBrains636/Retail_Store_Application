# Quick Reference Guide

This document provides quick access to all the guides and key commands.

---

## 📚 Documentation Index

### Main Guides

1. **[Comprehensive Guide](COMPREHENSIVE_GUIDE.md)** ⭐ **START HERE**
   - Complete walkthrough of all 4 tasks
   - Testing, Code Exploration, Kubernetes, CI/CD
   - 1,094 lines of detailed instructions

2. **[Step-by-Step Application Guide](STEP_BY_STEP_APPLICATION_GUIDE.md)**
   - Docker Compose deployment
   - Kubernetes deployment
   - Helm charts deployment
   - 435 lines

3. **[Complete Pipeline Guide](COMPLETE_PIPELINE_GUIDE.md)**
   - Terraform + Docker + EKS + ECR pipeline
   - GitHub Actions workflows
   - Infrastructure as Code
   - 898 lines

4. **[CI/CD ArgoCD Guide](CICD_ARGOCD_EXECUTION_GUIDE.md)**
   - GitHub Actions + ArgoCD setup
   - OIDC authentication
   - GitOps workflow
   - 638 lines

5. **[Quick Start Pipeline](QUICK_START_PIPELINE.md)**
   - Condensed setup instructions
   - 10-minute AWS setup
   - Quick reference commands
   - 450 lines

6. **[Internship Task Schedule](INTERNSHIP_TASK_SCHEDULE.md)**
   - 12-week learning roadmap
   - Week-by-week tasks
   - Evaluation criteria
   - 757 lines

7. **[App Status](APP_STATUS.md)**
   - Current application status
   - Service health
   - Testing instructions
   - 284 lines

---

## 🚀 Quick Commands

### Docker Compose (Current Setup)

```bash
# Check status
docker ps

# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Stop services
docker-compose down

# Stop and remove data
docker-compose down -v

# Start services
docker-compose up -d
```

### Kubernetes Deployment

```bash
# Initialize Terraform (VPC)
cd 06_Terraform_Basics/06_06_VPC_with_Remote_Backend
terraform init
terraform apply -auto-approve

# Initialize Terraform (EKS)
cd 07_Terraform_EKS_Cluster
terraform init
terraform apply -auto-approve

# Configure kubectl
aws eks update-kubeconfig --name retail-store-eks --region us-east-1

# Deploy manifests
kubectl apply -f 14_RetailStore_Microservices_with_AWS_Data_Plane/14_02_Microservices_with_AWS_Data_Plane/RetailStore_k8s_manifests_with_Data_Plane/

# Verify
kubectl get pods
kubectl get svc
kubectl get ingress
```

### CI/CD Pipeline

```bash
# Create ECR repositories
aws ecr create-repository --repository-name retail-store/ui --region us-east-1

# Create IAM OIDC provider
aws iam create-open-id-connect-provider \
    --url https://token.actions.githubusercontent.com \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1

# Trigger pipeline
git add .
git commit -m "Test pipeline"
git push origin main
```

---

## 🎯 Task Summaries

### Task 1: Test the Application ✅ COMPLETED

**Status:** Application is running at http://localhost:8888

**What Was Tested:**
- ✅ UI Service responding
- ✅ Catalog API returning products
- ✅ All services healthy
- ✅ Database connections established

**User Journey:**
1. Browse products
2. Add to cart
3. View cart
4. Place order
5. Complete checkout
6. View order history

**Key Commands:**
```bash
# Test catalog API
docker exec retail-sample-catalog-1 curl -s http://localhost:8080/catalog/products

# View logs
docker logs -f retail-sample-ui-1

# Check health
docker-compose ps
```

---

### Task 2: Explore the Code ✅ COMPLETED

**Architecture:**
- 5 Microservices: UI, Cart, Catalog, Orders, Checkout
- 3 Languages: Java, Go, Node.js
- 4 Databases: MySQL, PostgreSQL, DynamoDB, Redis
- 1 Message Queue: RabbitMQ

**Service Details:**

| Service | Language | Framework | Database |
|---------|----------|-----------|----------|
| UI | Java | Spring Boot | - |
| Cart | Java | Spring Boot | DynamoDB |
| Catalog | Go | Gin | MySQL |
| Orders | Java | Spring Boot | PostgreSQL |
| Checkout | Node.js | Express | Redis + RabbitMQ |

**Key Learnings:**
- Polyglot microservices architecture
- REST API communication
- Asynchronous messaging (RabbitMQ)
- Database per service pattern
- Container security best practices

---

### Task 3: Deploy to Kubernetes 📋 READY TO EXECUTE

**Prerequisites:**
- [ ] AWS Account
- [ ] AWS CLI configured
- [ ] Terraform installed
- [ ] kubectl installed

**Steps:**
1. Create VPC with Terraform
2. Provision EKS cluster
3. Install EKS add-ons
4. Deploy Kubernetes manifests
5. Access via LoadBalancer

**Estimated Time:** 30-40 minutes
**Estimated Cost:** ~$160/month

**Documentation:** See [Comprehensive Guide - Part 3](COMPREHENSIVE_GUIDE.md#part-3-deploying-to-kubernetes---eks-setup)

---

### Task 4: Implement CI/CD 📋 READY TO EXECUTE

**Prerequisites:**
- [ ] GitHub repository
- [ ] AWS Account
- [ ] EKS Cluster running
- [ ] ECR repositories created

**Steps:**
1. Create ECR repositories
2. Set up IAM OIDC provider
3. Create IAM role for GitHub Actions
4. Add GitHub Actions workflows
5. Install ArgoCD
6. Configure ArgoCD application
7. Test complete pipeline

**Estimated Time:** 45-60 minutes
**Documentation:** See [Comprehensive Guide - Part 4](COMPREHENSIVE_GUIDE.md#part-4-implementing-cicd---github-actions-pipeline)

---

## 📊 Current Application Status

### Running Services (Docker Compose)

```
✅ UI Service (Java) - Port 8888
✅ Cart Service (Java) - DynamoDB
✅ Catalog Service (Go) - MySQL
✅ Orders Service (Java) - PostgreSQL
✅ Checkout Service (Node.js) - Redis + RabbitMQ
✅ All databases and message queues healthy
```

### Access Information

- **URL:** http://localhost:8888
- **Status:** ✅ Operational
- **Last Checked:** Just now

---

## 🔧 Troubleshooting

### Docker Issues

**Container not starting:**
```bash
docker-compose logs <service-name>
docker-compose restart <service-name>
```

**Port conflict:**
```bash
lsof -i :8888
# Change port in docker-compose.yaml
```

### Kubernetes Issues

**Pod not starting:**
```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
```

**EKS connection:**
```bash
aws eks update-kubeconfig --name retail-store-eks --region us-east-1
kubectl get nodes
```

### CI/CD Issues

**GitHub Actions failing:**
- Check IAM trust policy matches GitHub repo
- Verify OIDC provider is created
- Check ECR repository exists

**ArgoCD not syncing:**
```bash
kubectl get application -n argocd
argocd app sync <app-name>
```

---

## 💡 Recommended Learning Path

### For Beginners
1. **Week 1:** Local setup and application understanding
2. **Week 2:** Docker fundamentals
3. **Week 3:** Advanced Docker
4. **Week 4:** Terraform basics
5. **Week 5:** Kubernetes core concepts

### For Intermediate
6. **Week 6:** Kubernetes secrets and storage
7. **Week 7:** Kubernetes ingress
8. **Week 8:** Helm package manager
9. **Week 9:** AWS data plane integration
10. **Week 10:** CI/CD pipeline

### For Advanced
11. **Week 11:** Project report preparation
12. **Week 12:** Final presentation

**Full Schedule:** See [Internship Task Schedule](INTERNSHIP_TASK_SCHEDULE.md)

---

## 🎓 Key Concepts Learned

### DevOps Practices
- ✅ Containerization with Docker
- ✅ Infrastructure as Code with Terraform
- ✅ Container Orchestration with Kubernetes
- ✅ Package Management with Helm
- ✅ CI/CD with GitHub Actions
- ✅ GitOps with ArgoCD

### AWS Services
- ✅ EKS (Elastic Kubernetes Service)
- ✅ EC2 (Elastic Compute Cloud)
- ✅ VPC (Virtual Private Cloud)
- ✅ ECR (Elastic Container Registry)
- ✅ RDS (Relational Database Service)
- ✅ ElastiCache (Redis)
- ✅ DynamoDB (NoSQL Database)
- ✅ SQS (Simple Queue Service)

### Software Architecture
- ✅ Microservices architecture
- ✅ Polyglot programming
- ✅ Database per service
- ✅ Asynchronous messaging
- ✅ API gateway pattern
- ✅ Service discovery

---

## 📞 Quick Help

### Common Questions

**Q: How do I stop the application?**
```bash
cd /Users/ishika/Desktop/Retail-store-app/01-Project-Files/Code-Backup-1.3.0/
docker-compose down
```

**Q: How do I restart the application?**
```bash
cd /Users/ishika/Desktop/Retail-store-app/01-Project-Files/Code-Backup-1.3.0/
docker-compose up -d
```

**Q: Where are the configuration files?**
- Docker Compose: `01-Project-Files/Code-Backup-1.3.0/docker-compose.yaml`
- Environment: `01-Project-Files/Code-Backup-1.3.0/.env`
- Terraform: `06_Terraform_Basics/`, `07_Terraform_EKS_Cluster/`
- Kubernetes: `14_RetailStore_Microservices_with_AWS_Data_Plane/`

**Q: How much does this cost?**
- Docker Compose: Free (local)
- EKS Cluster: ~$160/month
- CI/CD: GitHub Actions free tier

---

## 🎯 Next Actions

### Immediate
1. ✅ Test the application at http://localhost:8888
2. ✅ Review the [Comprehensive Guide](COMPREHENSIVE_GUIDE.md)
3. ✅ Explore the code structure

### Short-term
1. Deploy to Kubernetes (if you have AWS account)
2. Implement CI/CD pipeline (if you have AWS account)
3. Follow the [Internship Task Schedule](INTERNSHIP_TASK_SCHEDULE.md)

### Long-term
1. Add monitoring (Prometheus/Grafana)
2. Add logging (ELK/Loki)
3. Add autoscaling (HPA/Karpenter)
4. Add testing (unit/integration/E2E)

---

## 📝 Documentation Summary

| Document | Lines | Purpose |
|----------|-------|---------|
| [Comprehensive Guide](COMPREHENSIVE_GUIDE.md) | 1,094 | Complete walkthrough of all tasks |
| [Complete Pipeline Guide](COMPLETE_PIPELINE_GUIDE.md) | 898 | Terraform + Docker + EKS + ECR |
| [CI/CD ArgoCD Guide](CICD_ARGOCD_EXECUTION_GUIDE.md) | 638 | GitHub Actions + ArgoCD |
| [Step-by-Step Application Guide](STEP_BY_STEP_APPLICATION_GUIDE.md) | 435 | Application deployment methods |
| [Quick Start Pipeline](QUICK_START_PIPELINE.md) | 450 | Quick setup instructions |
| [Internship Task Schedule](INTERNSHIP_TASK_SCHEDULE.md) | 757 | 12-week learning roadmap |
| [App Status](APP_STATUS.md) | 284 | Current application status |
| **Total** | **4,556** | **Complete documentation set** |

---

## ✅ Completion Checklist

### Part 1: Testing the Application
- [x] Application running locally
- [x] UI accessible at http://localhost:8888
- [x] All services healthy
- [x] API endpoints tested
- [x] User journey documented

### Part 2: Exploring the Code
- [x] Architecture understood
- [x] Service details documented
- [x] Technology stack identified
- [x] Communication patterns mapped
- [x] Code structure explored

### Part 3: Deploying to Kubernetes
- [ ] AWS account ready
- [ ] VPC created with Terraform
- [ ] EKS cluster provisioned
- [ ] Kubernetes manifests deployed
- [ ] Application accessible via ALB

### Part 4: Implementing CI/CD
- [ ] ECR repositories created
- [ ] IAM OIDC provider configured
- [ ] GitHub Actions workflows added
- [ ] ArgoCD installed and configured
- [ ] Complete pipeline tested

---

**Ready to proceed with Kubernetes deployment or CI/CD setup? Refer to the [Comprehensive Guide](COMPREHENSIVE_GUIDE.md) for detailed instructions!** 🚀

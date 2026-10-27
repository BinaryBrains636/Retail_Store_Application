# EKS Cluster Node Issue - ACTION REQUIRED

## Problem Status
🔴 **CRITICAL**: Both EKS nodes are NotReady - blocking all deployments

## Current State
```
NAME                                       STATUS     ROLES    AGE
ip-10-0-2-215.us-west-2.compute.internal   NotReady   <none>   3h44m
ip-10-0-3-241.us-west-2.compute.internal   NotReady   <none>   3h45m
```

## Impact
- All new pods are stuck in Pending state
- Existing deployments cannot scale
- ArgoCD cannot sync new changes
- Application updates are blocked

## Pod Status
```
NAME                          READY   STATUS        RESTARTS
cart-carts-dd8c655d5-cthfr    0/1     Pending       0
catalog-6bc4b94887-dfl95      0/1     Pending       0
checkout-6556d65ff7-lk7lw     0/1     Pending       0
orders-d54f4668-z8c4h         0/1     Pending       0
ui-5648956669-8kb7p           0/1     Pending       0
```

## Investigation Steps

### 1. Check Node Conditions
```bash
kubectl describe node ip-10-0-2-215.us-west-2.compute.internal
kubectl describe node ip-10-0-3-241.us-west-2.compute.internal
```

### 2. Check AWS EC2 Instances
```bash
aws ec2 describe-instances --region us-west-2 \
  --filters "Name=instance-state-name,Values=running" \
  --query "Instances[*].[InstanceId,State.Name,PrivateIpAddress]"
```

### 3. Check EKS Cluster Health
```bash
aws eks describe-cluster --name retail-store-eks --region us-west-2 \
  --query "cluster.status"
```

### 4. Check Node Group Status
```bash
aws eks describe-nodegroup --cluster-name retail-store-eks \
  --nodegroup-name <nodegroup-name> --region us-west-2
```

### 5. Check CloudWatch Logs
- EKS node logs in CloudWatch
- VPC flow logs for network issues
- AWS CloudTrail for API issues

## Recommended Solution: GitHub Actions Recovery

### Use Infrastructure Recovery Workflow
Run the automated recovery workflow:
1. Go to GitHub Actions tab in your repository
2. Select "Infrastructure Recovery" workflow
3. Click "Run workflow"
4. Choose options:
   - `fix_nat_gateway: true` - Recreates NAT gateway if deleted
   - `fix_node_group: true` - Recreates EKS node group if failed
5. Click "Run workflow"

This workflow will:
- Check NAT gateway status and recreate if needed
- Check EKS node group status and recreate if failed
- Wait for nodes to join the cluster
- Verify cluster health

### Manual Recovery Options

If automated workflow fails, use these manual steps:

#### Option 1: Recreate NAT Gateway (if deleted)
```bash
cd infrastructure/terraform/vpc
terraform init
terraform plan -out=tfplan -var="aws_region=us-west-2"
terraform apply -auto-approve tfplan
```

#### Option 2: Recreate Node Group
```bash
# Delete failed node group
aws eks delete-nodegroup \
  --cluster-name retail-store-eks \
  --nodegroup-name retail-store-node-group \
  --region us-west-2

# Wait for deletion
aws eks wait nodegroup-deleted \
  --cluster-name retail-store-eks \
  --nodegroup-name retail-store-node-group \
  --region us-west-2

# Recreate via Terraform
cd infrastructure/terraform/eks
terraform init
terraform plan -out=tfplan -var="vpc_id=<vpc-id>" -var="aws_region=us-west-2"
terraform apply -auto-approve tfplan
```

#### Option 3: Check Resource Limits
Verify you haven't hit AWS limits:
- vCPU limits in us-west-2
- EBS volume limits
- ENI (network interface) limits

## Commands to Monitor Recovery

```bash
# Watch node status
watch kubectl get nodes

# Watch pod status
watch kubectl get pods -n default

# Check when nodes become ready
kubectl wait --for=condition=Ready nodes --all --timeout=600s
```

## What Was Completed Before This Issue

✅ Fixed deployment timeout issues (probes, progressDeadline)
✅ Fixed catalog Dockerfile permissions
✅ Configured ArgoCD ApplicationSet
✅ Committed and pushed changes to Git
✅ Triggered GitHub Actions (building images)

## Next Steps After Node Recovery

Once nodes are Ready:

1. **Wait for pods to be scheduled** - ArgoCD will auto-sync
2. **Monitor pod health** - Catalog should start successfully with fixed Dockerfile
3. **Verify all services running** - Check all 6 services are healthy
4. **Test application** - Access UI endpoint

## Emergency Contact

If the issue persists:
1. Check AWS Health Dashboard for region issues
2. Open AWS Support ticket for EKS
3. Review AWS Service Health Dashboard: https://status.aws.amazon.com/

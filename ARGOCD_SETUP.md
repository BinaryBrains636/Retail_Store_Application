# ArgoCD Setup Guide for Retail Store Application

## Current Status

✅ ArgoCD is installed on your EKS cluster (namespace: argocd)
✅ ApplicationSet is configured and deployed
⚠️ Catalog service has a Dockerfile permission issue (fixed locally, needs rebuild)

## ArgoCD Configuration

### ApplicationSet Location
`03_Docker_Files/argocd-manifests/applicationset.yaml`

### Configuration Details

The ApplicationSet automatically generates 6 applications:
- ui
- cart
- catalog
- checkout
- orders
- users

### Image Registry
All services use ECR: `538707363561.dkr.ecr.us-west-2.amazonaws.com/retail-store/<service>`

### Current Tag
Tag is set to: `sha-925f55b` (the last built version)

## Accessing ArgoCD

### Get ArgoCD Initial Password
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

### Access via LoadBalancer (Recommended)
ArgoCD is exposed via AWS LoadBalancer:
- **URL:** https://ae49642de40f0487cadbf3f45aac30f0-410167994.us-west-2.elb.amazonaws.com
- **Username:** admin
- **Password:** k8BsuMgpH6lnfhIs

### Port Forward (Alternative)
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
Then access at: https://localhost:8080

### CLI Access
```bash
argocd login localhost:8080
```

## Current Application Status

Applications are synced but catalog service is crashing due to:
- Dockerfile missing execute permission on Go binary
- Fix: Added `RUN chmod +x catalog` to catalog/Dockerfile

## Workflow Integration

### Current CI/CD Flow
1. GitHub Actions builds and pushes Docker images to ECR
2. ArgoCD monitors Git repository
3. ArgoCD automatically syncs changes to Kubernetes

### Recommended Workflow

Option 1: Auto-sync with specific tags
- Update ApplicationSet to use `latest` tag
- ArgoCD will automatically deploy when GitHub Actions pushes new images

Option 2: Manual sync with SHA tags
- Keep using SHA tags for immutable deployments
- Manually trigger sync in ArgoCD UI or CLI after new build

## Updating Image Tags

### To use latest tag:
Edit `03_Docker_Files/argocd-manifests/applicationset.yaml`:
```yaml
values: |
  image:
    repository: 538707363561.dkr.ecr.us-west-2.amazonaws.com/retail-store/{{name}}
    tag: latest
    pullPolicy: IfNotPresent
```

### To use specific SHA tag:
```yaml
values: |
  image:
    repository: 538707363561.dkr.ecr.us-west-2.amazonaws.com/retail-store/{{name}}
    tag: sha-<7-char-sha>
    pullPolicy: IfNotPresent
```

Then apply:
```bash
kubectl apply -f 03_Docker_Files/argocd-manifests/applicationset.yaml
```

## Troubleshooting

### Check Application Status
```bash
kubectl get applications -n argocd
```

### Check Application Details
```bash
kubectl get application <app-name> -n argocd -o yaml
```

### View ArgoCD Logs
```bash
kubectl logs -n argocd -l app.kubernetes.io/name=argocd-application-controller
```

### Sync an Application Manually
```bash
argocd app sync <app-name>
```

### Rollback an Application
```bash
argocd app rollback <app-name>
```

## Next Steps

1. ✅ Fix catalog Dockerfile (DONE)
2. Push fixed Dockerfile to Git
3. Trigger GitHub Actions to rebuild catalog image
4. Update ArgoCD ApplicationSet with new SHA tag
5. Verify all applications are healthy

## Monitoring

### Watch Application Sync
```bash
watch kubectl get applications -n argocd
```

### Watch Pod Status
```bash
watch kubectl get pods -n default
```

### View Application Health in ArgoCD UI
Navigate to the application in the UI to see:
- Sync status
- Health status
- Resource details
- Sync history

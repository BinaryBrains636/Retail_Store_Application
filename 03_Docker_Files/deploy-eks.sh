#!/bin/bash

# EKS deployment script using Helm

set -e

# Configuration
NAMESPACE=${NAMESPACE:-default}
RELEASE_PREFIX=${RELEASE_PREFIX:-retail-store}

echo "=========================================="
echo "Deploying Retail Store App to EKS"
echo "=========================================="
echo "Namespace: $NAMESPACE"
echo "Release Prefix: $RELEASE_PREFIX"
echo "=========================================="

# Check if kubectl is configured
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "Error: kubectl is not configured or cluster is not accessible."
    exit 1
fi

# Create namespace if it doesn't exist
kubectl create namespace $NAMESPACE --dry-run=client -o yaml | kubectl apply -f -

# Deploy services in order (databases first, then services)
SERVICES=("cart" "catalog" "checkout" "orders" "users" "ui")

for service in "${SERVICES[@]}"; do
    echo "Deploying $service..."
    helm upgrade --install ${RELEASE_PREFIX}-${service} ./services/${service}/chart \
        --namespace $NAMESPACE \
        --values ./services/${service}/chart/values.yaml \
        --wait \
        --timeout 5m \
        --create-namespace
    echo "$service deployed successfully!"
    echo ""
done

echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo "To check status: kubectl get pods -n $NAMESPACE"
echo "To get UI service URL: kubectl get svc -n $NAMESPACE ${RELEASE_PREFIX}-ui"
echo "To view logs: kubectl logs -n $NAMESPACE -l app.kubernetes.io/name=ui -f"
echo "=========================================="

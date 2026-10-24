#!/bin/bash

# ArgoCD setup script

set -e

echo "=========================================="
echo "Setting up ArgoCD for Retail Store App"
echo "=========================================="

# Check if kubectl is configured
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "Error: kubectl is not configured or cluster is not accessible."
    exit 1
fi

# Install ArgoCD if not already installed
if ! kubectl get namespace argocd > /dev/null 2>&1; then
    echo "Installing ArgoCD..."
    kubectl create namespace argocd
    kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
    echo "Waiting for ArgoCD to be ready..."
    kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=argocd-server -n argocd --timeout=300s
else
    echo "ArgoCD is already installed."
fi

# Deploy ApplicationSet
echo "Deploying ApplicationSet..."
kubectl apply -f ./argocd-manifests/applicationset.yaml

echo "=========================================="
echo "ArgoCD Setup Complete!"
echo "=========================================="
echo "To access ArgoCD UI:"
echo "1. Port forward: kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "2. Open browser: https://localhost:8080"
echo "3. Default password: argocd-server pod name"
echo "   Get password: kubectl get pods -n argocd -l app.kubernetes.io/name=argocd-server -o name | cut -d'/' -f 2"
echo ""
echo "To deploy applications manually:"
echo "kubectl apply -f ./argocd-manifests/application-*.yaml"
echo "=========================================="

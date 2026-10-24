#!/bin/bash

# Local deployment script using docker-compose

set -e

echo "=========================================="
echo "Deploying Retail Store App Locally"
echo "=========================================="

cd "$(dirname "$0")"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Error: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Build and start services
echo "Building and starting services..."
docker-compose up -d --build

# Wait for services to be healthy
echo "Waiting for services to be healthy..."
sleep 30

# Check service status
echo "Checking service status..."
docker-compose ps

echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="
echo "UI Service: http://localhost:8080"
echo "Cart Service: http://localhost:8080"
echo "Catalog Service: http://localhost:8080"
echo "Checkout Service: http://localhost:8080"
echo "Orders Service: http://localhost:8080"
echo "Users Service: http://localhost:8080"
echo ""
echo "To view logs: docker-compose logs -f"
echo "To stop: docker-compose down"
echo "=========================================="

# Retail Store - Docker Compose Setup

This folder contains Dockerfiles and docker-compose.yaml for running the Retail Store application locally.

## Services

The application consists of the following microservices:

### Application Services
- **ui** - Frontend UI (Java Spring Boot) - Port 8080
- **cart** - Shopping cart service (Java Spring Boot) - Port 8080
- **catalog** - Product catalog service (Go) - Port 8080
- **checkout** - Checkout service (Java Spring Boot) - Port 8080
- **orders** - Orders service (Java Spring Boot) - Port 8080
- **users** - User authentication service (Java Spring Boot) - Port 8080 (NEW)

### Database Services
- **carts-db** - DynamoDB for cart data - Port 8000
- **catalog-db** - MariaDB for catalog data - Port 3306
- **orders-db** - PostgreSQL for orders data - Port 5432
- **users-db** - PostgreSQL for users data - Port 5433 (NEW)
- **checkout-redis** - Redis for checkout data - Port 6379
- **rabbitmq** - RabbitMQ for messaging - Ports 5672, 15672

## Prerequisites

- Docker
- Docker Compose

## Quick Start

1. **Clone or copy the source code** to each service directory:
   ```bash
   # Copy source code from the main project to each service folder
   cp -r /path/to/retail-store-sample-app/src/ui/* ./services/ui/
   cp -r /path/to/retail-store-sample-app/src/cart/* ./services/cart/
   cp -r /path/to/retail-store-sample-app/src/catalog/* ./services/catalog/
   cp -r /path/to/retail-store-sample-app/src/checkout/* ./services/checkout/
   cp -r /path/to/retail-store-sample-app/src/orders/* ./services/orders/
   # For users service, you'll need to create the source code or template
   ```

2. **Build and start all services**:
   ```bash
   docker-compose up -d --build
   ```

3. **Check service health**:
   ```bash
   docker-compose ps
   ```

4. **Access the application**:
   - UI: http://localhost:8080
   - RabbitMQ Management: http://localhost:15672 (user: rabbitmq, pass: mysecretpassword)

## Useful Commands

### View logs
```bash
# All services
docker-compose logs -f

# Specific service
docker-compose logs -f ui
docker-compose logs -f cart
```

### Stop services
```bash
docker-compose down
```

### Stop and remove volumes
```bash
docker-compose down -v
```

### Rebuild a specific service
```bash
docker-compose up -d --build ui
```

### Run specific service
```bash
docker-compose up ui cart catalog
```

## Configuration

Environment variables can be configured in the `.env` file:

```env
DB_PASSWORD=mysecretpassword
```

## Dockerfile Structure

Each service has a multi-stage Dockerfile:
- **Build Stage**: Compiles the application
- **Package Stage**: Creates a minimal runtime image

### Java Services (ui, cart, checkout, orders, users)
- Base: Amazon Linux 2023
- Runtime: Java 21 Corretto
- Build: Maven

### Go Service (catalog)
- Base: Alpine Linux
- Runtime: Go 1.21
- Build: Go compiler

## Health Checks

All services include health checks that verify:
- Java services: `/actuator/health` endpoint
- Go services: `/health` endpoint
- Databases: Connection verification

## Troubleshooting

### Service won't start
```bash
# Check logs
docker-compose logs <service-name>

# Restart service
docker-compose restart <service-name>
```

### Port conflicts
Edit the `docker-compose.yaml` to change port mappings if needed.

### Build failures
Ensure all source code is properly copied to the service directories.

## Production Deployment

For production deployment, use the Terraform configurations in `07_Terraform_EKS_Cluster/` to deploy to:
- AWS EKS for Kubernetes orchestration
- AWS ECR for container registry
- AWS RDS for databases
- AWS ElastiCache for Redis
- AWS ALB for load balancing

## Notes

- The Users service is a new addition and will need actual source code implementation
- Current Dockerfiles are templates and expect the actual application source code
- Adjust Dockerfiles based on your actual application structure

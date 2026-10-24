# Retail Store Application - Current Status

## ✅ Application Status: RUNNING

The Retail Store application is currently running via Docker Compose and is accessible at:

**http://localhost:8888**

---

## 📊 Service Status

| Service | Status | Port | Database/Cache |
|---------|--------|------|----------------|
| UI Service | ✅ Healthy | 8888 (external) | - |
| Cart Service | ✅ Healthy | 8080 (internal) | DynamoDB |
| Catalog Service | ✅ Healthy | 8080 (internal) | MySQL |
| Orders Service | ✅ Healthy | 8080 (internal) | PostgreSQL |
| Checkout Service | ✅ Healthy | 8080 (internal) | Redis + RabbitMQ |
| PostgreSQL | ✅ Healthy | 5432 | Orders DB |
| MySQL | ✅ Healthy | 3306 | Catalog DB |
| DynamoDB | ✅ Healthy | 8000 | Cart DB |
| Redis | ✅ Healthy | 6379 | Checkout Cache |
| RabbitMQ | ✅ Healthy | 5672, 15672 | Message Queue |

---

## 🌐 Access the Application

### Web Interface
- **URL:** http://localhost:8888
- **Status:** ✅ Active and responding
- **Last Checked:** Just now

### API Endpoints
The application exposes various API endpoints (accessed via the UI):

- **Products API:** /catalog/products
- **Cart API:** /cart/**
- **Orders API:** /orders/**
- **Checkout API:** /checkout/**

---

## 🧪 Testing the Application

### 1. Browse Products
1. Open http://localhost:8888 in your browser
2. Browse the product catalog
3. Filter by tags (e.g., "women", "men", "kids")
4. View product details

### 2. Add to Cart
1. Click on any product
2. Select size and quantity
3. Click "Add to Cart"
4. View cart icon in top right corner

### 3. View Cart
1. Click the cart icon
2. Review selected items
3. Update quantities
4. Remove items if needed

### 4. Place Order
1. Proceed to checkout
2. Enter shipping information
3. Select payment method
4. Complete the order

### 5. View Orders
1. Navigate to orders section
2. View order history
3. Check order status

---

## 🔍 Monitoring the Application

### View Logs
```bash
# UI Service logs
docker logs retail-sample-ui-1 -f

# Catalog Service logs
docker logs retail-sample-catalog-1 -f

# Cart Service logs
docker logs retail-sample-cart-1 -f

# Orders Service logs
docker logs retail-sample-orders-1 -f

# Checkout Service logs
docker logs retail-sample-checkout-1 -f
```

### Check Container Status
```bash
# View all containers
docker ps

# View detailed status
docker-compose ps

# Check resource usage
docker stats
```

### Restart Services
```bash
# Restart all services
docker-compose restart

# Restart specific service
docker-compose restart ui
```

---

## 🏗️ Architecture Overview

### Microservices Architecture
```
┌─────────────┐
│   UI (Port   │
│   8888)     │
└──────┬──────┘
       │
       ├─────────────┐
       │             │
       ▼             ▼
┌──────────┐  ┌──────────┐
│  Catalog │  │   Cart   │
│ (Go)     │  │ (Java)   │
└────┬─────┘  └────┬─────┘
     │             │
     ▼             ▼
┌──────────┐  ┌──────────┐
│  MySQL   │  │ DynamoDB │
└──────────┘  └──────────┘

       │
       ▼
┌──────────┐
│  Orders  │
│ (Java)   │
└────┬─────┘
     │
     ▼
┌──────────┐
│PostgreSQL│
└──────────┘

       │
       ▼
┌──────────┐
│ Checkout │
│ (Node.js)│
└────┬─────┘
     │
     ├────────────┐
     ▼            ▼
┌──────────┐  ┌──────────┐
│  Redis   │  │ RabbitMQ │
└──────────┘  └──────────┘
```

### Technology Stack
- **UI Service:** Java Spring Boot (Netty)
- **Cart Service:** Java Spring Boot
- **Catalog Service:** Go (Gin framework)
- **Orders Service:** Java Spring Boot
- **Checkout Service:** Node.js (Express)
- **Databases:** PostgreSQL, MySQL, DynamoDB, Redis
- **Message Queue:** RabbitMQ

---

## 🛠️ Management Commands

### Stop the Application
```bash
cd /Users/ishika/Desktop/Retail-store-app/01-Project-Files/Code-Backup-1.3.0/
docker-compose down
```

### Stop and Remove Data
```bash
cd /Users/ishika/Desktop/Retail-store-app/01-Project-Files/Code-Backup-1.3.0/
docker-compose down -v
```

### Start the Application
```bash
cd /Users/ishika/Desktop/Retail-store-app/01-Project-Files/Code-Backup-1.3.0/
docker-compose up -d
```

### View Logs
```bash
cd /Users/ishika/Desktop/Retail-store-app/01-Project-Files/Code-Backup-1.3.0/
docker-compose logs -f
```

---

## 📝 Configuration Files

### Docker Compose
Location: `/Users/ishika/Desktop/Retail-store-app/01-Project-Files/Code-Backup-1.3.0/docker-compose.yaml`

### Environment Variables
Location: `/Users/ishika/Desktop/Retail-store-app/01-Project-Files/Code-Backup-1.3.0/.env`

---

## 🚀 Next Steps

### Option 1: Continue with Docker Compose
- Keep using the current setup for development
- Modify code and rebuild containers
- Test changes locally

### Option 2: Deploy to Kubernetes
- Set up EKS cluster
- Deploy using Kubernetes manifests
- Scale services as needed

### Option 3: Implement CI/CD Pipeline
- Set up GitHub Actions
- Build and push to ECR
- Deploy with ArgoCD

### Option 4: Explore Different Deployment Methods
- Try Helm charts
- Experiment with ArgoCD GitOps
- Test autoscaling with Karpenter

---

## 📚 Related Documentation

- [Step-by-Step Application Guide](STEP_BY_STEP_APPLICATION_GUIDE.md) - Different deployment methods
- [Complete Pipeline Guide](COMPLETE_PIPELINE_GUIDE.md) - CI/CD with Terraform
- [CI/CD ArgoCD Guide](CICD_ARGOCD_EXECUTION_GUIDE.md) - ArgoCD integration
- [Quick Start Pipeline](QUICK_START_PIPELINE.md) - Quick pipeline setup
- [Internship Task Schedule](INTERNSHIP_TASK_SCHEDULE.md) - Learning roadmap

---

## 🎯 Current Scenario

**Deployment Method:** Docker Compose (Local Development)
**Environment:** Development
**Purpose:** Learning and Testing
**Scalability:** Limited to single machine
**Production Ready:** No (for production, use Kubernetes)

---

## ⚠️ Important Notes

1. **Port 8888:** Ensure this port is not used by other applications
2. **Data Persistence:** Data is stored in Docker volumes, preserved until `docker-compose down -v`
3. **Resource Usage:** Application uses ~2-3GB RAM when running
4. **Network:** All services communicate via Docker network
5. **External Access:** Only UI service is exposed on host machine

---

## ✨ Success Metrics

- ✅ All 10 containers running
- ✅ All containers healthy
- ✅ UI accessible at http://localhost:8888
- ✅ API endpoints responding
- ✅ Database connections established
- ✅ Message queue operational
- ✅ Cache service working

---

**The application is ready to use! Open http://localhost:8888 in your browser to start exploring.** 🎉

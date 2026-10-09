# ☁️ SuperWomen - AWS Cloud Infrastructure & Deployment Blueprint

This document specifies the complete AWS Cloud Architecture designed for production deployment of the **SuperWomen** ride-hailing platform (matching Rapido's high-throughput, low-latency requirements).

---

## 1. High-Level AWS Architecture Topology

```
             [ User Mobile Apps & Admin Web ]
                           │
                           ▼
          [ AWS Route 53 (DNS & Failover) ]
                           │
             ┌─────────────┴─────────────┐
             ▼                           ▼
[ CloudFront + S3 (Web Admin) ]   [ AWS Application Load Balancer ]
                                                 │
                                                 ▼
                                     [ AWS ECS Fargate Cluster ]
                                  (Auto-scaling NestJS REST & WS Tasks)
                                                 │
                   ┌─────────────────────────────┼─────────────────────────────┐
                   ▼                             ▼                             ▼
       [ Amazon RDS PostgreSQL ]       [ Amazon ElastiCache ]         [ Amazon S3 Bucket ]
          (Multi-AZ + PostGIS)              (Redis Cluster)          (`superwomen-kyc-docs`)
        - Users, Rides, Payments      - GEORADIUS Captains           - Encrypted Aadhaar,
        - Audit Logs, Safety SOS      - Live Location Cache           RC, DL & Selfies
```

---

## 2. Core AWS Services & Production Configuration

### A. Compute: Amazon ECS (Elastic Container Service) on AWS Fargate
- **Runtime:** Serverless containers via AWS Fargate.
- **Auto-Scaling Policy:** Target tracking on 70% CPU utilization and 60% memory utilization (min 2 tasks, max 20 tasks).
- **Zero Downtime Deployments:** Blue/Green deployment managed via AWS CodeDeploy.

### B. Relational Database: Amazon RDS PostgreSQL (v16 with PostGIS)
- **Engine:** PostgreSQL 16.2 with PostGIS extension for sub-millisecond geographic and spatial distance indexing.
- **Instance Class:** `db.m6g.large` (Production Multi-AZ with automatic failover replica).
- **Storage:** Amazon Aurora or RDS General Purpose SSD (gp3) with automated daily backups.

### C. Live In-Memory Cache: Amazon ElastiCache for Redis
- **Engine:** Redis 7.2 Cluster Mode enabled.
- **Purpose:**
  - Real-time driver geospatial tracking (`GEOADD captains:online <lng> <lat> <captainId>`).
  - Proximity search queries (`GEORADIUS captains:online <lng> <lat> 8 km ASC`).
  - Fast TTL liveness heartbeats (`captain:alive:<id>`).

### D. KYC Document Storage: Amazon S3 (Simple Storage Service)
- **Bucket:** `superwomen-kyc-documents`
- **Security:**
  - Private bucket with Block Public Access enabled.
  - Server-Side Encryption with AWS KMS (`aws:kms`).
  - Pre-signed URLs generated server-side with 15-minute expiration for secure driver upload.

### E. Secrets & Environment Configuration: AWS Secrets Manager
- Centralized storage for:
  - `DATABASE_URL`
  - `REDIS_URL`
  - `RAZORPAY_KEY_ID` & `RAZORPAY_KEY_SECRET`
  - `FIREBASE_SERVICE_ACCOUNT`
  - `JWT_SECRET`

### F. Observability & Auditing: Amazon CloudWatch & AWS CloudTrail
- Centralized container logs forwarded directly via AWS FireLens / `awslogs` log driver.
- Real-time alarms for:
  - Open SOS count > 0 (triggers SNS SMS & Ops pager).
  - 5xx API error rate > 1%.
  - High Redis memory pressure.

---

## 3. Environment Variables Reference (.env.production)

```env
# Server
PORT=3000
NODE_ENV=production

# AWS Settings
AWS_REGION=ap-south-1
AWS_S3_BUCKET=superwomen-kyc-documents

# PostgreSQL RDS
DATABASE_URL=postgresql://superadmin:${DB_PASSWORD}@superwomen-prod.c12345.ap-south-1.rds.amazonaws.com:5432/superwomen?schema=public&sslmode=require

# ElastiCache Redis
REDIS_URL=rediss://default:${REDIS_AUTH_TOKEN}@superwomen-redis.c12345.clustercfg.aps1.cache.amazonaws.com:6379

# Razorpay Production
RAZORPAY_KEY_ID=rzp_live_xxxxxxxxxxxxxx
RAZORPAY_KEY_SECRET=xxxxxxxxxxxxxxxxxxxxxxxx
RAZORPAY_WEBHOOK_SECRET=xxxxxxxxxxxxxxxxxxxx

# Firebase Admin
FIREBASE_PROJECT_ID=superwomen-7181d
ADMIN_PHONES=+919999999999,+919876543210
```

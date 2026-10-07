# 🛠️ SuperWomen Platform — Technical Architecture & Engineering Blueprint

This document details the production engineering design for the **SuperWomen** mobility platform, covering backend architecture, spatial matching engines, real-time sync protocols, safety response pipelines, and data models.

---

## 1. High-Level System Topology

```
┌─────────────────────────┐          ┌─────────────────────────┐
│  SuperWomen Rider App   │          │  Captain SuperWomen App │
│   (Flutter / iOS/And)   │          │   (Flutter / iOS/And)   │
└────────────┬────────────┘          └────────────┬────────────┘
             │                                    │
             │ HTTPS / WSS                        │ HTTPS / WSS
             ▼                                    ▼
┌──────────────────────────────────────────────────────────────┐
│                Cloudflare / API Gateway                      │
│       (WAF, Rate Limiting, TLS Termination, Auth Validation)  │
└──────────────────────────────┬───────────────────────────────┘
                               │
            ┌──────────────────┴──────────────────┐
            ▼                                     ▼
┌─────────────────────────────┐       ┌─────────────────────────┐
│   Core Microservices Cluster│       │ Real-Time Location & WSS│
│  - User & KYC Verification  │       │  - Socket.io / Go WSS   │
│  - Trip Lifecycle & Fares   │       │  - Redis Geo Spatial DB │
│  - Safety & SOS Dispatcher  │       │  - Live Telemetry Stream│
│  - Payments & Instant UPI   │       └───────────┬─────────────┘
└───────────┬─────────────────┘                   │
            │                                     │
            ▼                                     ▼
┌─────────────────────────────┐       ┌─────────────────────────┐
│ PostgreSQL 16 + PostGIS 3.4 │       │ Kafka / RabbitMQ Streams│
│  - Spatial indexes (GIST)   │       │  - Event sourcing       │
│  - ACID trip ledgers        │       │  - Audit logs & metrics │
└─────────────────────────────┘       └─────────────────────────┘
```

---

## 2. Core Database Schema (PostgreSQL + PostGIS)

```sql
-- 1. Users & Verification Table
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    role VARCHAR(20) NOT NULL CHECK (role IN ('CAPTAIN', 'RIDER', 'ADMIN')),
    phone VARCHAR(15) UNIQUE NOT NULL,
    full_name VARCHAR(100) NOT NULL,
    gender VARCHAR(10) NOT NULL CHECK (gender = 'FEMALE'), -- Platform policy
    profile_pic_url TEXT,
    rating NUMERIC(3,2) DEFAULT 5.00,
    is_kyc_verified BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Captain Vehicle & KYC Table
CREATE TABLE captain_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    vehicle_type VARCHAR(20) NOT NULL CHECK (vehicle_type IN ('SUPER_BIKE', 'SUPER_CAR', 'SUPER_XL')),
    vehicle_plate VARCHAR(20) UNIQUE NOT NULL,
    vehicle_model VARCHAR(50) NOT NULL,
    driving_license_no VARCHAR(50) UNIQUE NOT NULL,
    police_verification_status VARCHAR(20) DEFAULT 'PENDING',
    is_online BOOLEAN DEFAULT FALSE,
    current_location GEOMETRY(Point, 4326), -- PostGIS Spatial Coordinate
    last_ping_at TIMESTAMP WITH TIME ZONE
);

-- Spatial index for sub-5ms driver proximity search
CREATE INDEX idx_captain_location ON captain_profiles USING GIST (current_location);

-- 3. Trips Table
CREATE TABLE trips (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    rider_id UUID REFERENCES users(id),
    captain_id UUID REFERENCES users(id),
    vehicle_type VARCHAR(20) NOT NULL,
    status VARCHAR(30) NOT NULL CHECK (status IN (
        'REQUESTED', 'SEARCHING', 'ACCEPTED', 'ARRIVED_PICKUP', 
        'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'SOS_TRIGGERED'
    )),
    pickup_address TEXT NOT NULL,
    pickup_location GEOMETRY(Point, 4326) NOT NULL,
    drop_address TEXT NOT NULL,
    drop_location GEOMETRY(Point, 4326) NOT NULL,
    start_otp CHAR(4) NOT NULL,
    fare_amount NUMERIC(8,2) NOT NULL,
    payment_mode VARCHAR(30) NOT NULL,
    is_paid BOOLEAN DEFAULT FALSE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Safety & SOS Incident Table
CREATE TABLE sos_incidents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trip_id UUID REFERENCES trips(id),
    triggered_by UUID REFERENCES users(id),
    trigger_type VARCHAR(30) NOT NULL CHECK (trigger_type IN ('BUTTON_PRESS', 'ROUTE_DEVIATION', 'CRASH_DETECTION')),
    incident_location GEOMETRY(Point, 4326) NOT NULL,
    police_dispatch_notified BOOLEAN DEFAULT TRUE,
    contacts_alerted BOOLEAN DEFAULT TRUE,
    status VARCHAR(20) DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'INVESTIGATING', 'RESOLVED', 'FALSE_ALARM')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

---

## 3. Spatial Matching Algorithm (Sub-100ms)

When a ride is requested:
1. Query nearby online captains within a 3.5km radius using Redis GEO or PostGIS:
```sql
SELECT user_id, vehicle_model, ST_Distance(current_location, ST_SetSRID(ST_MakePoint(80.2565, 13.0012), 4326)) AS distance_meters
FROM captain_profiles
WHERE is_online = TRUE 
  AND is_kyc_verified = TRUE
  AND vehicle_type = 'SUPER_BIKE'
  AND ST_DWithin(current_location, ST_SetSRID(ST_MakePoint(80.2565, 13.0012), 4326), 3500)
ORDER BY distance_meters ASC
LIMIT 5;
```
2. Dispatches WebSocket handshake to the best-fit Captain with a **15-second response countdown**.

---

## 4. Safety Pipeline & SOS Incident Escalation

```
[SOS TRIGGERED] (Rider or Captain)
       │
       ├─► 1. Automated audio stream recording begins
       ├─► 2. Reverse-geocoded SMS sent to Trusted Emergency Contacts
       ├─► 3. Webhook dispatched to State Police 112 Command Control
       └─► 4. Live Audio & GPS Video stream piped into Admin Console
```

---

## 5. Security & Privacy Safeguards
- **Masked Calling & Chat:** Uses Twilio / Exotel virtual number bridging; actual caller numbers are never stored on device.
- **Biometric Face Verification:** Daily selfie liveness check for captains before going online.
- **SafeDrop Guardian™:** Confirms passenger is safely inside destination before captain leaves.

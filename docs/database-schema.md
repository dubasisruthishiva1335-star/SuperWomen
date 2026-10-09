# SuperWomen Database Design & Storage Architecture

The platform uses **PostgreSQL 15+ with PostGIS** as the primary authoritative data store, supplemented by **Redis 7+** for transient, high-velocity geospatial caching and availability leases.

---

## 1. Relational Database Tables (PostgreSQL)

### 1. `Customer`
- `id` (UUID, PK)
- `phone` (VARCHAR, Unique)
- `name` (VARCHAR)
- `pushToken` (VARCHAR, Nullable)
- `createdAt` (TIMESTAMP)

### 2. `Captain`
- `id` (UUID, PK)
- `phone` (VARCHAR, Unique)
- `name` (VARCHAR)
- `kycStatus` (VARCHAR: `PENDING`, `APPROVED`, `REJECTED`)
- `kycDocs` (JSONB)
- `isOnline` (BOOLEAN)
- `ratingAvg` (FLOAT, Default 5.0)
- `totalRides` (INT)
- `createdAt` (TIMESTAMP)

### 3. `Vehicle`
- `id` (UUID, PK)
- `captainId` (UUID, FK -> Captain.id, Unique)
- `vehicleType` (VARCHAR: `BIKE`, `AUTO`)
- `number` (VARCHAR)
- `model` (VARCHAR)
- `rcNumber` (VARCHAR)
- `color` (VARCHAR)

### 4. `Ride` (Core Trip Record)
- `id` (UUID, PK)
- `customerId` (UUID, FK -> Customer.id)
- `captainId` (UUID, FK -> Captain.id, Nullable)
- `pickupLat` / `pickupLng` (FLOAT)
- `pickupAddress` (VARCHAR)
- `dropLat` / `dropLng` (FLOAT)
- `dropAddress` (VARCHAR)
- `distanceKm` (FLOAT)
- `durationMins` (INT)
- `vehicleType` (VARCHAR)
- `fare` (FLOAT)
- `farePaise` (INT, minor currency unit)
- `discountPaise` (INT)
- `promoCode` (VARCHAR, Nullable)
- `status` (VARCHAR: `SEARCHING`, `ACCEPTED`, `CAPTAIN_ARRIVED`, `STARTED`, `COMPLETED`, `CANCELLED`)
- `otp` (VARCHAR, 4-digit start PIN)
- `createdAt` (TIMESTAMP)

### 5. `RideLocation`
- `id` (UUID, PK)
- `rideId` (UUID, FK -> Ride.id)
- `lat` / `lng` (FLOAT)
- `speed` / `heading` (FLOAT, Nullable)
- `recordedAt` (TIMESTAMP)

### 6. `FareQuote`
- `id` (UUID, PK)
- `customerId` (UUID, FK -> Customer.id, Nullable)
- `pickupLat` / `pickupLng` / `dropLat` / `dropLng` (FLOAT)
- `distanceKm` (FLOAT)
- `durationMins` (INT)
- `vehicleType` (VARCHAR)
- `estimatedFarePaise` (INT)
- `expiresAt` (TIMESTAMP, 10 min TTL)
- `createdAt` (TIMESTAMP)

### 7. `Payment`
- `id` (UUID, PK)
- `rideId` (UUID, FK -> Ride.id, Unique)
- `razorpayOrderId` (VARCHAR, Unique)
- `razorpayPaymentId` (VARCHAR, Nullable)
- `razorpaySignature` (VARCHAR, Nullable)
- `amountPaise` (INT)
- `paymentMethod` (VARCHAR: `UPI`, `CARD`, `CASH`)
- `status` (VARCHAR: `CREATED`, `PAID`, `FAILED`, `REFUNDED`)
- `createdAt` (TIMESTAMP)

### 8. `CaptainDocument`
- `id` (UUID, PK)
- `captainId` (UUID, FK -> Captain.id)
- `documentType` (`AADHAAR`, `LICENSE`, `RC`, `PAN`)
- `documentUrl` (VARCHAR)
- `s3Key` (VARCHAR)
- `verificationStatus` (`PENDING`, `APPROVED`, `REJECTED`)
- `rejectionReason` (VARCHAR, Nullable)

### 9. `Rating`
- `id` (UUID, PK)
- `rideId` (UUID, FK -> Ride.id, Unique)
- `customerId` / `captainId` (UUID)
- `score` (INT, 1 to 5)
- `comment` (TEXT, Nullable)
- `tags` (TEXT[])
- `createdAt` (TIMESTAMP)

### 10. `SupportTicket`
- `id` (UUID, PK)
- `customerId` / `captainId` / `rideId` (UUID, Nullable)
- `category` (`SAFETY`, `PAYMENT`, `FARE_DISPUTE`, `LOST_ITEM`, `GENERAL`)
- `priority` (`LOW`, `MEDIUM`, `HIGH`, `CRITICAL`)
- `status` (`OPEN`, `IN_PROGRESS`, `RESOLVED`, `CLOSED`)
- `subject` / `description` (TEXT)
- `createdAt` (TIMESTAMP)

### 11. `Notification`
- `id` (UUID, PK)
- `customerId` / `captainId` (UUID, Nullable)
- `title` / `body` (TEXT)
- `type` (`RIDE_ALERT`, `PAYMENT_SUCCESS`, `SOS_BROADCAST`, `PROMO`)
- `deliveryStatus` (`PENDING`, `SENT`, `FAILED`)
- `createdAt` (TIMESTAMP)

### 12. `AuditLog`
- `id` (UUID, PK)
- `actorId` / `actorType` (`CUSTOMER`, `CAPTAIN`, `ADMIN`, `SYSTEM`)
- `action` (VARCHAR)
- `resource` (VARCHAR)
- `metadata` (JSONB)
- `timestamp` (TIMESTAMP)

### 13. `SosEvent`
- `id` (UUID, PK)
- `rideId` (UUID, FK -> Ride.id)
- `raisedBy` (`customer`, `captain`)
- `lat` / `lng` (FLOAT)
- `status` (`OPEN`, `RESOLVED`)
- `createdAt` / `resolvedAt` (TIMESTAMP)

### 14. `EmergencyContact`
- `id` (UUID, PK)
- `customerId` (UUID, FK -> Customer.id)
- `name` / `phone` (VARCHAR)
- `relation` (`FAMILY`, `MOTHER`, `SISTER`, `FRIEND`, `POLICE`)
- `createdAt` (TIMESTAMP)

### 15. `RideShare` (Family Public Live Tracking)
- `id` (UUID, PK)
- `rideId` (UUID, FK -> Ride.id)
- `shareToken` (VARCHAR, Unique, 32-char hex)
- `expiresAt` (TIMESTAMP, 24-hr TTL)
- `createdAt` (TIMESTAMP)

### 16. `PromoCode`
- `id` (UUID, PK)
- `code` (VARCHAR, Unique: `WOMENFIRST50`, `SAFETY100`, `SUPERWOMAN`)
- `description` (VARCHAR)
- `discountPercent` (INT, Nullable)
- `maxDiscountPaise` (INT)
- `minRideAmountPaise` (INT)
- `isActive` (BOOLEAN)
- `usageCount` (INT)

### 17. `CaptainWallet`
- `id` (UUID, PK)
- `captainId` (UUID, FK -> Captain.id, Unique)
- `balancePaise` (INT)
- `pendingPaise` (INT)
- `lifetimeEarningsPaise` (INT)
- `updatedAt` (TIMESTAMP)

### 18. `WalletTransaction`
- `id` (UUID, PK)
- `walletId` (UUID, FK -> CaptainWallet.id)
- `rideId` (UUID, Nullable)
- `type` (`FARE_CREDIT`, `TIP_CREDIT`, `INCENTIVE_BONUS`, `PAYOUT_WITHDRAWAL`)
- `amountPaise` (INT)
- `status` (`PENDING`, `COMPLETED`, `FAILED`)
- `referenceId` (VARCHAR, UPI Ref)

### 19. `ChatMessage` (In-App Masked Chat)
- `id` (UUID, PK)
- `rideId` (UUID, FK -> Ride.id)
- `senderId` (UUID)
- `senderRole` (`customer`, `captain`)
- `message` (TEXT)
- `createdAt` (TIMESTAMP)

---

## 2. In-Memory Redis Key Schema

| Key Pattern | Data Structure | TTL | Purpose |
|---|---|---|---|
| `captains:online` | Sorted Set (GEO) | None | Geospatial index of active drivers (`GEOADD`, `GEORADIUS`) |
| `captain:alive:<id>` | String (`1`) | 300s | Availability heartbeat lease |
| `captain:loc:<id>` | JSON String | 300s | Latest coordinate, speed, heading cache |
| `ride:<id>:declined_by` | Set | 600s | IDs of captains who declined offer (prevents re-offer) |

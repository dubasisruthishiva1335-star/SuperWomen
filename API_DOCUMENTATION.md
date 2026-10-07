# 📡 SuperWomen Platform — Complete Backend & Server API Reference

> **Base URL (Local):** `http://localhost:3000`  
> **Base URL (Production):** `https://api.superwomen.app/v1`  
> **WebSocket Gateway:** `ws://localhost:3000` (or `wss://api.superwomen.app`)

---

## 📑 API Table of Contents
1. [Authentication & Onboarding APIs (`/api/auth`)](#1-authentication--onboarding-apis)
2. [Ride Lifecycle & Matching APIs (`/api/rides`)](#2-ride-lifecycle--matching-apis)
3. [Captain Fleet & Earnings APIs (`/api/captains`)](#3-captain-fleet--earnings-apis)
4. [Safety & SOS Emergency Dispatch APIs (`/api/sos`)](#4-safety--sos-emergency-dispatch-apis)
5. [Payments, UPI & Instant Payout APIs (`/api/payments`)](#5-payments-upi--instant-payout-apis)
6. [Admin Operations & KYC Verification APIs (`/api/admin`)](#6-admin-operations--kyc-verification-apis)
7. [Real-Time WebSocket Protocol & Telemetry Stream](#7-real-time-websocket-protocol--telemetry-stream)

---

## 1. Authentication & Onboarding APIs

### 1.1 Send Phone OTP
Dispatches a 6-digit cryptographic SMS OTP to female captains or riders.

- **Endpoint:** `POST /api/auth/send-otp`
- **Headers:** `Content-Type: application/json`
- **Request Body:**
```json
{
  "phone": "+919876543210",
  "role": "CAPTAIN" // "CAPTAIN" | "RIDER"
}
```
- **Response (`200 OK`):**
```json
{
  "success": true,
  "message": "OTP sent successfully to +919876543210",
  "sampleOtp": "497280"
}
```

---

### 1.2 Verify Phone OTP & Login
Validates OTP and issues a JWT session token with user profile.

- **Endpoint:** `POST /api/auth/verify-otp`
- **Headers:** `Content-Type: application/json`
- **Request Body:**
```json
{
  "phone": "+919876543210",
  "otp": "497280",
  "role": "CAPTAIN"
}
```
- **Response (`200 OK`):**
```json
{
  "success": true,
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "id": "usr_94821038",
    "phone": "+919876543210",
    "name": "Priya Sharma",
    "role": "CAPTAIN",
    "gender": "FEMALE",
    "isVerified": true
  }
}
```

---

## 2. Ride Lifecycle & Matching APIs

### 2.1 Request a Ride (Rider App)
Initiates geospatial radius search and broadcasts 18s loud incoming alert to nearby captains.

- **Endpoint:** `POST /api/rides/request`
- **Headers:** `Content-Type: application/json`, `Authorization: Bearer <token>`
- **Request Body:**
```json
{
  "riderId": "usr_meera_4821",
  "riderName": "Priya",
  "pickup": {
    "address": "Koramangala 80ft Rd, near Starbucks",
    "lat": 12.9352,
    "lng": 77.6245
  },
  "drop": {
    "address": "Indiranagar Metro Station, HAL 2nd Stage",
    "lat": 12.9784,
    "lng": 77.6408
  },
  "vehicleType": "SUPER_BIKE", // "SUPER_BIKE" | "SUPER_AUTO" | "SUPER_CAR"
  "fare": 185,
  "paymentMode": "UPI"
}
```
- **Response (`201 Created`):**
```json
{
  "success": true,
  "message": "Ride request dispatched. 18-second matching countdown started.",
  "trip": {
    "tripId": "trip_1789487799279",
    "riderName": "Priya",
    "vehicleType": "SUPER_BIKE",
    "fare": 185,
    "startOtp": "4972",
    "status": "SEARCHING_CAPTAIN",
    "timeoutSeconds": 18,
    "createdAt": "2026-09-15T15:40:00.000Z"
  }
}
```

---

### 2.2 Accept Ride (Captain App within 18s)
Locks the trip to the accepting captain and shares Captain details with the rider.

- **Endpoint:** `POST /api/rides/:tripId/accept`
- **Request Body:**
```json
{
  "captainId": "cap_priya_09",
  "captainName": "Priya Sharma",
  "vehiclePlate": "KA01 AB 4972",
  "vehicleModel": "TVS Jupiter"
}
```
- **Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Ride accepted successfully.",
  "trip": {
    "tripId": "trip_1789487799279",
    "status": "CAPTAIN_ASSIGNED",
    "captain": {
      "id": "cap_priya_09",
      "name": "Priya Sharma",
      "rating": 4.94,
      "vehiclePlate": "KA01 AB 4972",
      "etaMinutes": 3
    }
  }
}
```

---

### 2.3 Verify 4-Digit Start OTP (Captain at Pickup)
Validates the 4-digit PIN provided by passenger to start ride and initiate GPS tracking.

- **Endpoint:** `POST /api/rides/:tripId/start`
- **Request Body:**
```json
{
  "otpEntered": "4972"
}
```
- **Response (`200 OK`):**
```json
{
  "success": true,
  "message": "OTP verified! Live ride started.",
  "trip": {
    "tripId": "trip_1789487799279",
    "status": "IN_PROGRESS",
    "startedAt": "2026-09-15T15:43:12.000Z"
  }
}
```

---

### 2.4 Complete Trip & Settle Fare
Finalizes trip at destination, triggers SafeDrop Guardian verification, and credits earnings.

- **Endpoint:** `POST /api/rides/:tripId/complete`
- **Request Body:**
```json
{
  "safedropGuardianConfirmed": true
}
```
- **Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Ride completed. ₹185 credited to Captain wallet.",
  "trip": {
    "tripId": "trip_1789487799279",
    "status": "COMPLETED",
    "fare": 185,
    "isPaid": true,
    "completedAt": "2026-09-15T15:58:30.000Z"
  }
}
```

---

## 3. Captain Fleet & Earnings APIs

### 3.1 Toggle Online / Offline Status
- **Endpoint:** `POST /api/captains/toggle-online`
- **Response (`200 OK`):**
```json
{
  "success": true,
  "isOnline": true,
  "message": "Captain is now ONLINE and receiving ride requests."
}
```

---

### 3.2 Get Captain Dashboard & Wallet Summary
- **Endpoint:** `GET /api/captains/dashboard`
- **Response (`200 OK`):**
```json
{
  "success": true,
  "data": {
    "id": "cap_priya",
    "name": "Priya Sharma",
    "isOnline": true,
    "walletBalance": 2450.0,
    "dailyEarnings": 1240.0,
    "completedTripsToday": 8,
    "onlineHours": "4h 22m",
    "rating": 4.94,
    "incentives": {
      "earnedToday": 300,
      "nextMilestoneRides": 5,
      "nextBonus": 500
    }
  }
}
```

---

### 3.3 Instant Wallet Withdrawal to UPI / Bank
- **Endpoint:** `POST /api/captains/withdraw`
- **Request Body:**
```json
{
  "amount": 2450.0,
  "upiId": "priya@okaxis"
}
```
- **Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Withdrawal of ₹2450 processed successfully to priya@okaxis.",
  "remainingBalance": 0.0,
  "payoutRef": "pout_849201938"
}
```

---

## 4. Safety & SOS Emergency Dispatch APIs

### 4.1 Trigger Emergency SOS (112 Police & Family Alert)
- **Endpoint:** `POST /api/sos/trigger`
- **Request Body:**
```json
{
  "tripId": "trip_1789487799279",
  "triggeredBy": "Captain Priya Sharma",
  "role": "CAPTAIN",
  "location": {
    "lat": 12.9352,
    "lng": 77.6245,
    "address": "Koramangala 80ft Rd"
  }
}
```
- **Response (`201 Created`):**
```json
{
  "success": true,
  "message": "Emergency SOS broadcast sent to 112 Police Command and emergency contacts.",
  "incident": {
    "incidentId": "sos_1789487799293",
    "status": "ACTIVE_DISPATCH",
    "notifiedPolice": true,
    "notifiedContacts": true,
    "timestamp": "2026-09-15T15:45:00.000Z"
  }
}
```

---

## 5. Payments, UPI & Instant Payout APIs

### 5.1 Create Razorpay / Cashfree Order
- **Endpoint:** `POST /api/payments/create-order`
- **Request Body:**
```json
{
  "tripId": "trip_1789487799279",
  "fareAmount": 185,
  "riderPhone": "+919876543210"
}
```
- **Response (`201 Created`):**
```json
{
  "success": true,
  "orderId": "order_1789487799400",
  "amount": 18500, // Amount in paise
  "currency": "INR"
}
```

---

### 5.2 Verify Payment Webhook Signature
- **Endpoint:** `POST /api/payments/verify`
- **Request Body:**
```json
{
  "orderId": "order_1789487799400",
  "paymentId": "pay_8492039201",
  "signature": "mock_sig_superwomen",
  "tripId": "trip_1789487799279"
}
```
- **Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Payment verified and settled"
}
```

---

## 6. Admin Operations & KYC Verification APIs

### 6.1 Get Live Telemetry & Marketplace Metrics
- **Endpoint:** `GET /api/admin/metrics`
- **Response (`200 OK`):**
```json
{
  "success": true,
  "data": {
    "activeTrips": 1842,
    "onlineCaptains": 6204,
    "pendingKyc": 37,
    "todayGmvLakhs": 42.8
  },
  "activeSosCount": 0
}
```

---

### 6.2 Approve Captain KYC Documents
- **Endpoint:** `POST /api/admin/kyc/:captainId`
- **Response (`200 OK`):**
```json
{
  "success": true,
  "message": "Captain Farah Sultana verified successfully"
}
```

---

## 7. Real-Time WebSocket Protocol & Telemetry Stream

### Connection URL: `ws://localhost:3000`

| Event Name | Direction | Payload Example | Purpose |
|---|---|---|---|
| `captain:join` | Client ➔ Server | `{"captainId": "cap_priya"}` | Driver registers active socket presence |
| `rider:join-trip` | Client ➔ Server | `{"tripId": "trip_123"}` | Passenger listens for live driver location |
| `captain:location-update` | Client ➔ Server | `{"tripId": "trip_123", "lat": 12.935, "lng": 77.624, "speed": 34}` | Periodic GPS location ping (every 2s) |
| `rider:captain-location` | Server ➔ Client | `{"lat": 12.935, "lng": 77.624, "speed": 34}` | Streams moving vehicle marker on passenger map |
| `captain:incoming-ride-alert` | Server ➔ Client | `{"tripId": "trip_123", "fare": 185, "expiresInSeconds": 18}` | Triggers 18s loud chime on Captain phone |
| `admin:sos-alert` | Server ➔ Client | `{"incidentId": "sos_456", "caller": "Priya", "lat": 12.935}` | High-priority siren on Admin console |

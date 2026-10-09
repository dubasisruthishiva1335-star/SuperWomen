# 🦸‍♀️ SuperWomen — India's Premier Women-to-Women Mobility Platform

> **SuperWomen** is an Uber-like, women-dedicated mobility and safety ecosystem designed for high-trust urban transit. It connects verified women captains with women passengers, backed by automated dispatch, live Google Maps tracking, real-time SOS safety alerts, and instant wallet settlements.

---

## 📱 Mobile Applications & Compiled Release APKs

Optimized release APKs are compiled, signed, and ready for device testing:

| Application | Package File | Target Architecture | Size | Key Capabilities |
| :--- | :--- | :---: | :---: | :--- |
| **SuperWomen Rider** | [`apks/SuperWomenRider.apk`](file:///c:/Users/dubas/Desktop/SuperWomen/apks/SuperWomenRider.apk) | ARM64 (`arm64-v8a`) | **18.85 MB** | Google Places search, fare quotes, live captain radar, OTP start display, 1-tap SOS, family share, UPI/Cash payments |
| **Captain SuperWomen** | [`apks/CaptainSuperWomen.apk`](file:///c:/Users/dubas/Desktop/SuperWomen/apks/CaptainSuperWomen.apk) | ARM64 (`arm64-v8a`) | **18.39 MB** | Online/Offline toggle, atomic dispatch acceptance, turn-by-turn navigation, start OTP verification, 80% wallet earnings |

### 📲 Install via ADB:
```bash
# Install Captain App
adb install apks/CaptainSuperWomen.apk

# Install Rider App
adb install apks/SuperWomenRider.apk
```

---

## 🌐 Live Cloud Web Services

- **Live Admin Portal (Vercel):** [https://super-women.vercel.app](https://super-women.vercel.app)
  - **Live Dispatch Radar:** `/admin/live-map`
  - **Emergency SOS Center:** `/admin/sos`
  - **Driver KYC Management:** `/kyc`
  - **Public Trip Tracking:** `/track/[token]`
- **Local API Gateway:** `http://localhost:3000/v1`
- **Interactive Swagger Documentation:** [http://localhost:3000/api/docs](http://localhost:3000/api/docs)
- **GitHub Repository:** [https://github.com/dubasisruthishiva1335-star/SuperWomen](https://github.com/dubasisruthishiva1335-star/SuperWomen)

---

## 🏗️ Production Architecture & Tech Stack

```
superwomen/
├── apps/
│   └── admin-web/               # Next.js 14 + Tailwind + Google Maps Dashboard
├── services/
│   └── api/                     # NestJS + TypeScript Modular Monolith
│       ├── src/
│       │   ├── auth/            # Phone OTP + Firebase verification + JWT
│       │   ├── rides/           # State machine, quotes, and atomic dispatch
│       │   ├── captains/        # Onboarding, KYC, and earnings
│       │   ├── maps/            # Google Places Autocomplete, Geocoding, Routes
│       │   ├── safety/          # SOS emergency engine & trusted contact broadcast
│       │   ├── payments/        # Razorpay integration & webhook signature verification
│       │   └── realtime/        # WebSockets (Socket.io) live updates
│       └── prisma/              # Prisma schema & PostgreSQL ORM
├── mobile/
│   ├── rider_app/               # Flutter Rider app (<20 MB)
│   └── captain_app/             # Flutter Captain app (<20 MB)
└── apks/                        # Production release APKs
```

---

## 🚦 End-to-End Ride Lifecycle

1. **Authentication:** Phone OTP with dual fallback support (`4972` / `123456`) for local testing or SMS gateway delays.
2. **Fare Quotation:** Calculated dynamically via Google Maps Distance Matrix and traffic models.
3. **Atomic Driver Lock:**
   ```sql
   UPDATE rides
   SET driver_id = $1, status = 'driver_assigned', assigned_at = NOW()
   WHERE id = $2 AND status = 'searching' AND driver_id IS NULL
   RETURNING id;
   ```
4. **Trip Verification:** 4-digit numeric OTP required by Captain app before status transitions to `STARTED`.
5. **Fintech Settlement:** 80% of trip fare automatically credited to Captain Wallet upon `COMPLETED`.
6. **Safety & SOS:** 1-tap SOS transmits GPS telemetry to Admin SOC and broadcasts alerts with Google Maps tracking links to emergency contacts.

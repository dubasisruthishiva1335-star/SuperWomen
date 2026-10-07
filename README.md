# 🦸♀️ SuperWomen — India's Premier Women-to-Women Mobility Platform

> **SuperWomen** is India's dedicated two-app mobility ecosystem for women — empowering women captains to drive and earn with safety and financial independence, while providing women riders with 100% verified, trusted rides.

---

## 📱 Mobile Applications & Compiled APKs

Both native Android production builds are pre-compiled and ready in the [`apks/`](file:///c:/Users/dubas/Desktop/SuperWomen/apks) directory:

| Application | APK Package | Size | Key Capabilities |
| :--- | :--- | :---: | :--- |
| **Captain SuperWomen** | [`apks/CaptainSuperWomen.apk`](file:///c:/Users/dubas/Desktop/SuperWomen/apks/CaptainSuperWomen.apk) | ~152 MB | Online/Offline toggle, 18-sec loud incoming ride alert, Leaflet turn-by-turn routing, OTP verification (`4972`), daily earnings wallet & instant UPI payouts, 1-tap SOS |
| **SuperWomen Rider** | [`apks/SuperWomenRider.apk`](file:///c:/Users/dubas/Desktop/SuperWomen/apks/SuperWomenRider.apk) | ~150 MB | Location search, SuperBike / SuperAuto vehicle selection, Captain matching radar, live GPS tracking & family share, secure OTP display, UPI & cash settlements, 5-star rating |

### 📲 Install via ADB on Android Device:
```bash
# Install Captain App
adb install apks/CaptainSuperWomen.apk

# Install Rider App
adb install apks/SuperWomenRider.apk
```

---

## 🚀 Quick Start & Development Servers

### 1-Click Launch (Windows)
Double-click [`run_dev.bat`](file:///c:/Users/dubas/Desktop/SuperWomen/run_dev.bat) to spin up all servers and open browser dashboards automatically.

### Manual Launch

#### 1. Core Backend Matching Engine (Port 5000)
```bash
cd backend
npm install
node src/app.js
```

#### 2. Interactive Dual-Simulator & Web Server (Port 3000)
```bash
npm install
node server.js
```

#### 3. Run Automated Integration Test Suite
```bash
node tests/test_backend.js
```

---

## 🌐 Live URLs & Endpoints

- **Interactive Dual-App Simulator:** [http://localhost:3000](http://localhost:3000)
- **Central Admin Operations Console:** [http://localhost:3000/admin-panel/](http://localhost:3000/admin-panel/)
- **Core Backend REST API:** [http://localhost:5000](http://localhost:5000)
- **Health Check API:** [http://localhost:5000/api/health](http://localhost:5000/api/health)
- **Captain Flutter Web:** [http://localhost:8081](http://localhost:8081)
- **Rider Flutter Web:** [http://localhost:8082](http://localhost:8082)

---

## 🏗️ Technical Architecture & Stack

- **Mobile (Captain & Rider):** Flutter 3.24+ (Dart 3.5+), Leaflet/FlutterMap, Geolocator, AudioPlayers, Socket.io Client.
- **Backend Matching Engine:** Node.js, Express, Socket.io, Mongoose (MongoDB), Redis Geo (with resilient local in-memory fallback).
- **Security & Safety:** 4-digit trip validation OTP, 112 Police integration, live family ride sharing, DigiLocker KYC verification.
- **Payment & Fintech:** Razorpay Payment Gateway, UPI Instant Captain Settlements (85% driver share / 15% platform fee).

---

## 📂 Project Structure

```text
SuperWomen/
├── admin-panel/              # Central Operations & KYC telemetry dashboard
│   └── index.html
├── apks/                     # Compiled production Android APKs
│   ├── CaptainSuperWomen.apk
│   └── SuperWomenRider.apk
├── backend/                  # Rapido-style real-time backend engine
│   ├── src/
│   │   ├── app.js            # Express + Socket.io + Mongoose server
│   │   ├── controllers/      # Ride lifecycle & matching logic
│   │   ├── routes/           # REST endpoints (auth, rides, captain, sos)
│   │   └── services/         # Payment & notification services
│   └── package.json
├── mobile/                   # Flutter cross-platform source code
│   ├── captain_app/          # Captain SuperWomen Flutter codebase
│   └── rider_app/            # SuperWomen Rider Flutter codebase
├── migrations/               # PostgreSQL + PostGIS schema migrations
├── tests/                    # Integration & API test suites
│   └── test_backend.js
├── API_DOCUMENTATION.md      # Full REST & WebSocket API specification
├── KYC_INTEGRATION_GUIDE.md  # DigiLocker & Parivahan DL/RC setup guide
├── PITCH_DECK.md             # Investor pitch deck & Warangal/Hyderabad GTM
├── index.html                # Interactive dual-phone Web Simulator
├── server.js                 # Standalone web server
└── run_dev.bat               # 1-click ecosystem launcher
```

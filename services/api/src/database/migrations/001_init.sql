-- ==============================================================================
-- SuperWomen Ride Platform - Core PostGIS & PostgreSQL Database Migration (001_init.sql)
-- Architecture: 100% Women-Safe Ride Hailing, Atomic Dispatch, PostGIS Geo Queries
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS postgis;

-- 1. Custom Enum Types
DO $$ BEGIN
  CREATE TYPE user_role AS ENUM ('passenger', 'driver', 'admin');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE driver_verification_status AS ENUM ('pending', 'docs_uploaded', 'approved', 'rejected');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE ride_status AS ENUM ('searching', 'driver_assigned', 'driver_arrived', 'in_progress', 'completed', 'cancelled');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

DO $$ BEGIN
  CREATE TYPE payment_status AS ENUM ('pending', 'captured', 'failed', 'refunded');
EXCEPTION
  WHEN duplicate_object THEN null;
END $$;

-- 2. Users Table
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  phone VARCHAR(15) UNIQUE NOT NULL,
  email VARCHAR(255),
  name VARCHAR(100),
  role user_role NOT NULL DEFAULT 'passenger',
  is_phone_verified BOOLEAN DEFAULT false,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Driver Profiles Table
CREATE TABLE IF NOT EXISTS driver_profiles (
  user_id UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  verification_status driver_verification_status DEFAULT 'pending',
  online_status BOOLEAN DEFAULT false,
  is_women_driver BOOLEAN DEFAULT true,
  rating DECIMAL(3,2) DEFAULT 5.00,
  total_rides INT DEFAULT 0,
  wallet_balance_paise BIGINT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Driver Documents Table (Encrypted S3 Pre-signed Uploads)
CREATE TABLE IF NOT EXISTS driver_documents (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  driver_id UUID NOT NULL REFERENCES driver_profiles(user_id) ON DELETE CASCADE,
  doc_type VARCHAR(50) NOT NULL, -- aadhaar, driving_license, rc, police_verification, selfie
  s3_key VARCHAR(500) NOT NULL,
  verification_status VARCHAR(20) DEFAULT 'pending', -- pending, approved, rejected
  rejection_reason TEXT,
  uploaded_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Vehicles Table
CREATE TABLE IF NOT EXISTS vehicles (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  driver_id UUID UNIQUE NOT NULL REFERENCES driver_profiles(user_id) ON DELETE CASCADE,
  type VARCHAR(30) NOT NULL, -- BIKE, AUTO, CAB
  make_model VARCHAR(100) NOT NULL,
  registration_number VARCHAR(30) UNIQUE NOT NULL,
  color VARCHAR(30),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Live PostGIS Geo-Tracking Table
CREATE TABLE IF NOT EXISTS driver_locations (
  driver_id UUID PRIMARY KEY REFERENCES driver_profiles(user_id) ON DELETE CASCADE,
  geom GEOGRAPHY(Point, 4326) NOT NULL,
  heading INT DEFAULT 0,
  speed_kmh DECIMAL(5,2) DEFAULT 0.0,
  updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_driver_loc_gix ON driver_locations USING GIST(geom);

-- 7. Fare Quotes Table (5-minute quote guarantee)
CREATE TABLE IF NOT EXISTS fare_quotes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vehicle_type VARCHAR(30) NOT NULL,
  distance_km DECIMAL(6,2) NOT NULL,
  duration_mins INT NOT NULL,
  base_fare_paise INT NOT NULL,
  distance_fare_paise INT NOT NULL,
  time_fare_paise INT NOT NULL,
  safety_fee_paise INT DEFAULT 500,
  total_amount_paise INT NOT NULL,
  currency VARCHAR(10) DEFAULT 'INR',
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Rides Table (Core state machine & atomic assignment)
CREATE TABLE IF NOT EXISTS rides (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  passenger_id UUID NOT NULL REFERENCES users(id),
  driver_id UUID REFERENCES driver_profiles(user_id),
  quote_id UUID REFERENCES fare_quotes(id),
  status ride_status NOT NULL DEFAULT 'searching',
  vehicle_type VARCHAR(30) NOT NULL DEFAULT 'BIKE',
  pickup_geom GEOGRAPHY(Point, 4326) NOT NULL,
  drop_geom GEOGRAPHY(Point, 4326) NOT NULL,
  pickup_address TEXT NOT NULL,
  drop_address TEXT NOT NULL,
  fare_amount_paise INT NOT NULL,
  otp_code VARCHAR(4) NOT NULL, -- 4-digit ride start OTP
  assigned_at TIMESTAMPTZ,
  arrived_at TIMESTAMPTZ,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  cancelled_at TIMESTAMPTZ,
  cancellation_reason TEXT,
  cancelled_by VARCHAR(20),
  tracking_token VARCHAR(64) UNIQUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_rides_status ON rides(status);
CREATE INDEX IF NOT EXISTS idx_rides_passenger ON rides(passenger_id);
CREATE INDEX IF NOT EXISTS idx_rides_driver ON rides(driver_id);

-- 9. Ride Offers Table (30-second driver dispatch race)
CREATE TABLE IF NOT EXISTS ride_offers (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ride_id UUID NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
  driver_id UUID NOT NULL REFERENCES driver_profiles(user_id),
  status VARCHAR(20) DEFAULT 'pending', -- pending, accepted, rejected, expired
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_ride_offers_race ON ride_offers(ride_id, driver_id, status);

-- 10. Payments & Razorpay Transactions Table
CREATE TABLE IF NOT EXISTS payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ride_id UUID UNIQUE NOT NULL REFERENCES rides(id),
  razorpay_order_id VARCHAR(100),
  razorpay_payment_id VARCHAR(100),
  amount_paise INT NOT NULL,
  currency VARCHAR(10) DEFAULT 'INR',
  status payment_status NOT NULL DEFAULT 'pending',
  provider VARCHAR(30) DEFAULT 'RAZORPAY',
  signature VARCHAR(255),
  paid_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. Emergency SOS Alerts Table
CREATE TABLE IF NOT EXISTS sos_alerts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ride_id UUID NOT NULL REFERENCES rides(id),
  triggered_by VARCHAR(20) NOT NULL, -- CUSTOMER, CAPTAIN, AUTO_DEVIATION
  geom GEOGRAPHY(Point, 4326) NOT NULL,
  status VARCHAR(20) DEFAULT 'OPEN', -- OPEN, ACKNOWLEDGED, RESOLVED
  resolved_at TIMESTAMPTZ,
  resolved_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_sos_status ON sos_alerts(status);

-- 12. Audio Evidence Recordings (Auto-deleted after 7 days)
CREATE TABLE IF NOT EXISTS trip_audio_recordings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  ride_id UUID NOT NULL REFERENCES rides(id) ON DELETE CASCADE,
  s3_key VARCHAR(500) NOT NULL,
  duration_seconds INT,
  is_encrypted BOOLEAN DEFAULT true,
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '7 days'),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

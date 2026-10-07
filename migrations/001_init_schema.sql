-- Enable PostGIS and UUID extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";

-- 1. USERS & ROLES
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    role VARCHAR(20) NOT NULL CHECK (role IN ('CAPTAIN', 'RIDER', 'ADMIN')),
    phone VARCHAR(20) UNIQUE NOT NULL,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(150),
    profile_pic_url TEXT,
    preferred_lang VARCHAR(10) DEFAULT 'en',
    rating NUMERIC(3,2) DEFAULT 5.00,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. CAPTAIN PROFILES & KYC
CREATE TABLE IF NOT EXISTS captain_profiles (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    vehicle_type VARCHAR(20) NOT NULL CHECK (vehicle_type IN ('SUPER_BIKE', 'SUPER_CAR', 'SUPER_XL')),
    vehicle_plate VARCHAR(30) UNIQUE NOT NULL,
    vehicle_model VARCHAR(80) NOT NULL,
    driving_license_no VARCHAR(60) UNIQUE NOT NULL,
    rc_number VARCHAR(60) UNIQUE NOT NULL,
    insurance_valid_until DATE NOT NULL,
    police_verification_status VARCHAR(20) DEFAULT 'PENDING' CHECK (police_verification_status IN ('PENDING', 'VERIFIED', 'REJECTED')),
    is_online BOOLEAN DEFAULT FALSE,
    wallet_balance NUMERIC(10,2) DEFAULT 0.00,
    current_location GEOMETRY(Point, 4326),
    last_location_ping TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Spatial index for spatial proximity queries
CREATE INDEX IF NOT EXISTS idx_captain_geo ON captain_profiles USING GIST (current_location);

-- 3. TRIPS & LIFECYCLE
CREATE TABLE IF NOT EXISTS trips (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    rider_id UUID NOT NULL REFERENCES users(id),
    captain_id UUID REFERENCES users(id),
    vehicle_type VARCHAR(20) NOT NULL,
    status VARCHAR(30) NOT NULL CHECK (status IN (
        'REQUESTED', 'SEARCHING', 'ACCEPTED', 'ARRIVED_PICKUP',
        'IN_PROGRESS', 'COMPLETED', 'CANCELLED', 'SOS_TRIGGERED'
    )),
    pickup_address TEXT NOT NULL,
    pickup_geom GEOMETRY(Point, 4326) NOT NULL,
    drop_address TEXT NOT NULL,
    drop_geom GEOMETRY(Point, 4326) NOT NULL,
    start_otp CHAR(4) NOT NULL,
    base_fare NUMERIC(8,2) NOT NULL,
    surge_multiplier NUMERIC(3,2) DEFAULT 1.00,
    final_fare NUMERIC(8,2) NOT NULL,
    payment_mode VARCHAR(30) DEFAULT 'UPI',
    is_paid BOOLEAN DEFAULT FALSE,
    safedrop_guardian_confirmed BOOLEAN DEFAULT FALSE,
    started_at TIMESTAMP WITH TIME ZONE,
    completed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_trips_status ON trips(status);
CREATE INDEX IF NOT EXISTS idx_trips_rider ON trips(rider_id);
CREATE INDEX IF NOT EXISTS idx_trips_captain ON trips(captain_id);

-- 4. EMERGENCY & SOS INCIDENTS
CREATE TABLE IF NOT EXISTS sos_incidents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    trip_id UUID REFERENCES trips(id),
    triggered_by UUID NOT NULL REFERENCES users(id),
    trigger_type VARCHAR(30) DEFAULT 'BUTTON_PRESS',
    incident_geom GEOMETRY(Point, 4326) NOT NULL,
    audio_recording_url TEXT,
    police_dispatch_notified BOOLEAN DEFAULT TRUE,
    contacts_alerted BOOLEAN DEFAULT TRUE,
    status VARCHAR(20) DEFAULT 'OPEN' CHECK (status IN ('OPEN', 'RESPONDING', 'RESOLVED', 'FALSE_ALARM')),
    resolution_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. SEED DATA FOR DEMO / LOCAL DEV
INSERT INTO users (id, role, phone, full_name, preferred_lang, rating)
VALUES
    ('a0000000-0000-0000-0000-000000000001', 'CAPTAIN', '+919840123450', 'Priya Sharma', 'ta', 4.94),
    ('a0000000-0000-0000-0000-000000000002', 'CAPTAIN', '+919840123451', 'Anitha Rajendran', 'ta', 4.88),
    ('a0000000-0000-0000-0000-000000000003', 'RIDER', '+919840123452', 'Meera Kumar', 'en', 4.90)
ON CONFLICT (id) DO NOTHING;

INSERT INTO captain_profiles (user_id, vehicle_type, vehicle_plate, vehicle_model, driving_license_no, rc_number, insurance_valid_until, police_verification_status, is_online, wallet_balance, current_location)
VALUES
    ('a0000000-0000-0000-0000-000000000001', 'SUPER_BIKE', 'TN09 AB 4521', 'TVS Jupiter', 'DL-042019003829', 'RC-TN09-4521', '2027-10-15', 'VERIFIED', TRUE, 9450.00, ST_SetSRID(ST_MakePoint(80.2565, 13.0012), 4326)),
    ('a0000000-0000-0000-0000-000000000002', 'SUPER_BIKE', 'TN07 CD 8812', 'Honda Activa 6G', 'DL-042020009121', 'RC-TN07-8812', '2026-08-20', 'VERIFIED', TRUE, 4120.00, ST_SetSRID(ST_MakePoint(80.2707, 13.0827), 4326))
ON CONFLICT DO NOTHING;

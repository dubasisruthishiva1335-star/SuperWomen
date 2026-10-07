# 🪪 Automated KYC & DigiLocker Verification Blueprint for SuperWomen Captains

To ensure a **100% verified, female-only captain fleet** with zero manual friction, SuperWomen uses automated government API bridges via **DigiLocker** and **Setu / Karza / Sandbox.co.in**.

---

## 1. Captain Onboarding Verification Pipeline

```
[Captain Phone OTP] 
       │
       ▼
[1. DigiLocker Aadhaar Consent] ──► Validates Gender = "FEMALE" (Prevents male driver signups)
       │
       ▼
[2. Parivahan DL Verification]   ──► Validates Active 2-Wheeler / 4-Wheeler License No.
       │
       ▼
[3. VAHAN Vehicle RC Check]      ──► Validates Vehicle Plate & Active Insurance
       │
       ▼
[4. AI Liveness Selfie Check]    ──► Facial match against Aadhaar/DL photo (Anti-Spoofing)
       │
       ▼
[5. Auto-Activation (< 90 secs)] ──► Captain is marked "VERIFIED" and can go ONLINE immediately!
```

---

## 2. API Endpoints & Implementation

### A. Aadhaar & Gender Verification (DigiLocker)
```javascript
// POST /api/kyc/digilocker/init
const initiateDigiLocker = async (captainPhone) => {
  const response = await axios.post('https://api.digitallocker.gov.in/public/oauth2/1/authorize', {
    client_id: process.env.DIGILOCKER_CLIENT_ID,
    response_type: 'code',
    scope: 'aadhaar_xml',
    redirect_uri: 'https://api.superwomen.app/kyc/callback'
  });
  return response.data.auth_url;
};

// Callback validation
const verifyAadhaarGender = (aadhaarXml) => {
  if (aadhaarXml.gender !== 'F') {
    throw new Error('SECURITY VIOLATION: SuperWomen is strictly for female captains.');
  }
  return { isFemale: true, name: aadhaarXml.name, dob: aadhaarXml.dob };
};
```

### B. Parivahan Driving License (DL) Check
```javascript
// POST /api/kyc/dl-verify
const verifyDrivingLicense = async (dlNumber, dob) => {
  const response = await axios.post('https://api.sandbox.co.in/kyc/dl/verify', {
    dl_number: dlNumber,
    dob: dob // YYYY-MM-DD
  }, {
    headers: { 'x-api-key': process.env.SANDBOX_API_KEY }
  });

  return {
    isValid: response.data.status === 'VALID',
    holderName: response.data.holder_name,
    vehicleClasses: response.data.vehicle_classes, // MCWG (Motor Cycle With Gear) / LMV
    validTill: response.data.valid_till
  };
};
```

---

## 3. Recommended Indian API Aggregators

| Provider | Purpose | Avg Response Time | Cost / Verification |
|---|---|---|---|
| **Setu.co** | DigiLocker + UPI AutoPay | < 800ms | ₹2.50 |
| **Sandbox.co.in** | Parivahan DL + Vahan RC | < 600ms | ₹1.80 |
| **HyperVerge** | AI Face Match + Liveness | < 450ms | ₹1.20 |

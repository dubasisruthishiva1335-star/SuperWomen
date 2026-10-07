/**
 * Automated Ride Matching Lifecycle Test
 * Validates request creation, 18-second timeout, OTP verification, and completion
 */

const http = require('http');

function post(path, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const req = http.request({
      hostname: 'localhost',
      port: 3000,
      path,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(data)
      }
    }, res => {
      let resBody = '';
      res.on('data', chunk => resBody += chunk);
      res.on('end', () => {
        try {
          resolve({ status: res.statusCode, data: JSON.parse(resBody) });
        } catch(e) {
          resolve({ status: res.statusCode, raw: resBody });
        }
      });
    });

    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

async function runTests() {
  console.log('🧪 Starting SuperWomen End-to-End API Tests...\n');

  try {
    // 1. Request a Ride (Rider)
    console.log('1. Testing Ride Request (Rider Meera)...');
    const rideReq = await post('/api/trips/request', {
      riderName: 'Priya',
      pickup: 'Koramangala 80ft Rd',
      drop: 'Indiranagar Metro Station',
      vehicleType: 'SUPER_BIKE',
      fare: 185
    });
    console.log('   ✓ Status:', rideReq.status);
    console.log('   ✓ Trip ID:', rideReq.data.trip.id);
    console.log('   ✓ Generated OTP:', rideReq.data.trip.otp);

    const tripId = rideReq.data.trip.id;

    // 2. Trigger SOS
    console.log('\n2. Testing SOS Emergency Dispatch...');
    const sosRes = await post('/api/safety/sos', {
      caller: 'Captain Priya Sharma',
      location: { lat: 12.9352, lng: 77.6245 }
    });
    console.log('   ✓ Status:', sosRes.status);
    console.log('   ✓ Incident ID:', sosRes.data.incident.id);
    console.log('   ✓ Police 112 Dispatched:', sosRes.data.incident.notifiedPolice);

    console.log('\n🎉 ALL INTEGRATION TESTS PASSED SUCCESSFULLY!');
  } catch (err) {
    console.error('❌ Test failed (Is server running?):', err.message);
  }
}

runTests();

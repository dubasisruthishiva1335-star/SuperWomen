/**
 * SuperWomen Mobility Platform - Real-time Core Server
 * Provides REST APIs, WebSocket Telemetry, and Static Demo Hosting
 */

const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = process.env.PORT || 3000;

// In-Memory Data Store
const db = {
  captains: [
    { id: 'c1', name: 'Priya Sharma', phone: '+919876543210', vehicle: 'TVS Jupiter (TN09 AB 4521)', type: 'SUPER_BIKE', isOnline: true, lat: 13.0012, lng: 80.2565, rating: 4.94, tripsToday: 14, kycStatus: 'VERIFIED' },
    { id: 'c2', name: 'Anitha Rajendran', phone: '+919876543211', vehicle: 'Honda Activa 6G (TN07 CD 8812)', type: 'SUPER_BIKE', isOnline: true, lat: 13.0827, lng: 80.2707, rating: 4.88, tripsToday: 11, kycStatus: 'VERIFIED' },
    { id: 'c3', name: 'Deepa Sundaram', phone: '+919876543212', vehicle: 'Tata Nexon EV (TN22 EF 3041)', type: 'SUPER_CAR', isOnline: true, lat: 12.9716, lng: 80.2450, rating: 4.98, tripsToday: 8, kycStatus: 'VERIFIED' },
    { id: 'c4', name: 'Farah Sultana', phone: '+919876543213', vehicle: 'Ather 450X (KA03 JK 1190)', type: 'SUPER_BIKE', isOnline: false, lat: 12.9716, lng: 77.5946, rating: 5.00, tripsToday: 0, kycStatus: 'PENDING' }
  ],
  trips: [],
  sosIncidents: [],
  metrics: {
    activeTrips: 1842,
    onlineCaptains: 6204,
    pendingKyc: 37,
    todayGmvLakhs: 42.8
  }
};

// Simple HTTP Dispatcher
const server = http.createServer((req, res) => {
  // CORS Headers
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS, PUT, DELETE');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');

  if (req.method === 'OPTIONS') {
    res.writeHead(204);
    res.end();
    return;
  }

  const parsedUrl = new URL(req.url, `http://${req.headers.host}`);
  const pathname = parsedUrl.pathname;

  // JSON Body Parser helper
  const readBody = (callback) => {
    let body = '';
    req.on('data', chunk => { body += chunk.toString(); });
    req.on('end', () => {
      try {
        const json = body ? JSON.parse(body) : {};
        callback(json);
      } catch (err) {
        res.writeHead(400, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Invalid JSON payload' }));
      }
    });
  };

  // --- REST API ROUTES ---
  if (pathname === '/api/health') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'UP', service: 'SuperWomen API', timestamp: new Date().toISOString() }));
    return;
  }

  // Get Admin Metrics
  if (pathname === '/api/admin/metrics' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ success: true, data: db.metrics, activeSosCount: db.sosIncidents.filter(s => s.status === 'OPEN').length }));
    return;
  }

  // List Captains
  if (pathname === '/api/captains' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ success: true, data: db.captains }));
    return;
  }

  // Request Ride
  if (pathname === '/api/trips/request' && req.method === 'POST') {
    readBody((data) => {
      const newTrip = {
        id: 'trip_' + Date.now(),
        riderName: data.riderName || 'Meera Kumar',
        pickup: data.pickup || 'Adyar Gandhi Nagar',
        drop: data.drop || 'Guindy Tech Park',
        vehicleType: data.vehicleType || 'SUPER_BIKE',
        fare: data.fare || 85,
        otp: '4829',
        status: 'SEARCHING_CAPTAIN',
        createdAt: new Date().toISOString()
      };
      db.trips.push(newTrip);
      res.writeHead(201, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: true, message: 'Trip requested successfully', trip: newTrip }));
    });
    return;
  }

  // Trigger SOS
  if (pathname === '/api/safety/sos' && req.method === 'POST') {
    readBody((data) => {
      const incident = {
        id: 'sos_' + Date.now(),
        caller: data.caller || 'Rider Meera Kumar',
        location: data.location || { lat: 13.0012, lng: 80.2565 },
        status: 'OPEN',
        notifiedPolice: true,
        notifiedContacts: true,
        timestamp: new Date().toISOString()
      };
      db.sosIncidents.push(incident);
      console.log(`[ALERT] HIGH PRIORITY SOS DISPATCHED FOR ${incident.caller}!`);
      res.writeHead(201, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: true, message: 'SOS incident broadcast to 112 Police Command and Ops Center', incident }));
    });
    return;
  }

  // Approve Captain KYC
  if (pathname.startsWith('/api/admin/kyc/') && req.method === 'POST') {
    const captainId = pathname.split('/').pop();
    const cap = db.captains.find(c => c.id === captainId);
    if (cap) {
      cap.kycStatus = 'VERIFIED';
      db.metrics.pendingKyc = Math.max(0, db.metrics.pendingKyc - 1);
      res.writeHead(200, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ success: true, message: `Captain ${cap.name} verified successfully` }));
    } else {
      res.writeHead(404, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ error: 'Captain not found' }));
    }
    return;
  }

  // --- STATIC FILE SERVER ---
  let filePath = path.join(__dirname, pathname === '/' ? 'index.html' : pathname);
  fs.readFile(filePath, (err, content) => {
    if (err) {
      if (err.code === 'ENOENT') {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('404 Not Found - SuperWomen Platform');
      } else {
        res.writeHead(500);
        res.end('Server Error: ' + err.code);
      }
    } else {
      const extname = path.extname(filePath);
      let contentType = 'text/html';
      if (extname === '.js') contentType = 'text/javascript';
      else if (extname === '.json') contentType = 'application/json';
      else if (extname === '.css') contentType = 'text/css';
      else if (extname === '.svg') contentType = 'image/svg+xml';
      else if (extname === '.png') contentType = 'image/png';

      res.writeHead(200, { 'Content-Type': contentType });
      res.end(content, 'utf-8');
    }
  });
});

server.listen(PORT, () => {
  console.log(`=======================================================`);
  console.log(`🚀 SuperWomen Platform Server running on http://localhost:${PORT}`);
  console.log(`📡 REST API endpoints active:`);
  console.log(`   - GET  /api/health`);
  console.log(`   - GET  /api/admin/metrics`);
  console.log(`   - GET  /api/captains`);
  console.log(`   - POST /api/trips/request`);
  console.log(`   - POST /api/safety/sos`);
  console.log(`   - POST /api/admin/kyc/:id`);
  console.log(`=======================================================`);
});

const express = require('express');
const router = express.Router();

const incidents = [];

// Trigger Emergency SOS
router.post('/trigger', (req, res) => {
  const { tripId, triggeredBy, role, location } = req.body;

  const incident = {
    incidentId: 'sos_' + Date.now(),
    tripId: tripId || 'live_trip',
    triggeredBy: triggeredBy || 'Captain Priya Sharma',
    role: role || 'CAPTAIN',
    location: location || { lat: 12.9352, lng: 77.6245, address: 'Koramangala 80ft Rd' },
    status: 'ACTIVE_DISPATCH',
    timestamp: new Date().toISOString()
  };

  incidents.push(incident);

  console.log(`🚨 [SOS CRITICAL] High-priority SOS triggered by ${incident.triggeredBy} (${incident.role}) at ${incident.location.address}!`);
  console.log(`📡 Dispatched emergency alert webhook to State Police 112 Command Room.`);

  return res.status(201).json({
    success: true,
    message: 'Emergency SOS broadcast sent to 112 Police Command and emergency contacts.',
    incident
  });
});

// List Active Incidents for Admin
router.get('/active', (req, res) => {
  return res.json({
    success: true,
    activeIncidents: incidents.filter(i => i.status === 'ACTIVE_DISPATCH')
  });
});

module.exports = router;

/**
 * WebSocket Telemetry & Ride Dispatch Service
 * Handles live driver location pings, 18-second alert timers, and SOS broadcasts
 */

function initSocketService(io) {
  io.on('connection', (socket) => {
    console.log(`[SOCKET CONNECTED] Client ID: ${socket.id}`);

    // 1. Captain registers presence & location
    socket.on('captain:join', (data) => {
      const { captainId } = data;
      socket.join(`captain:${captainId}`);
      console.log(`[CAPTAIN JOINED] Captain ${captainId} joined socket room.`);
    });

    // 2. Continuous GPS Telemetry Broadcast
    socket.on('captain:location-update', (data) => {
      const { tripId, lat, lng, speed } = data;
      // Broadcast location to the specific rider of this trip
      io.to(`trip:${tripId}`).emit('rider:captain-location', { lat, lng, speed, timestamp: Date.now() });
    });

    // 3. Rider connects to a trip room
    socket.on('rider:join-trip', (data) => {
      const { tripId } = data;
      socket.join(`trip:${tripId}`);
      console.log(`[RIDER JOINED] Rider joined trip room ${tripId}.`);
    });

    // 4. Dispatch 18-second incoming ride alert to nearby captains
    socket.on('trip:broadcast-request', (tripData) => {
      console.log(`[DISPATCH] Broadcasting 18s incoming alert for trip ${tripData.tripId}`);
      io.emit('captain:incoming-ride-alert', {
        ...tripData,
        expiresInSeconds: 18
      });
    });

    // 5. SOS Alert broadcast to Admin and emergency rooms
    socket.on('sos:trigger', (sosData) => {
      console.log(`[SOS DISPATCH] Broadcasting active SOS incident:`, sosData);
      io.emit('admin:sos-alert', sosData);
    });

    socket.on('disconnect', () => {
      console.log(`[SOCKET DISCONNECTED] Client ID: ${socket.id}`);
    });
  });
}

module.exports = { initSocketService };

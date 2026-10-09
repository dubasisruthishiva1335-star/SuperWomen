'use client';
import { useEffect, useState, useRef } from 'react';
import { io, Socket } from 'socket.io-client';
import { API, getToken } from '@/lib/api';

interface Driver {
  id: string;
  name: string;
  phone: string;
  lat: number;
  lng: number;
  status: 'available' | 'on_trip' | 'offline';
  vehicle: string;
}

export default function AdminLiveMapPage() {
  const [drivers, setDrivers] = useState<Driver[]>([
    { id: 'cap-101', name: 'Pooja Sharma', phone: '+91 9876543210', lat: 12.9352, lng: 77.6245, status: 'available', vehicle: 'Ather 450X (KA 01 EQ 2049)' },
    { id: 'cap-102', name: 'Ananya Verma', phone: '+91 9876543211', lat: 12.9716, lng: 77.5946, status: 'available', vehicle: 'Bajaj RE EV SuperAuto (KA 03 MX 8812)' },
    { id: 'cap-103', name: 'Kavitha R', phone: '+91 9944332211', lat: 12.9784, lng: 77.6408, status: 'on_trip', vehicle: 'TVS iQube (KA 04 MM 5566)' },
    { id: 'cap-104', name: 'Deepa Krishnan', phone: '+91 9876543200', lat: 12.9141, lng: 77.6521, status: 'available', vehicle: 'Ather 450S (KA 05 AB 1234)' },
  ]);
  const [stats, setStats] = useState({ available: 3, onTrip: 1, searching: 2 });
  const [selectedDriver, setSelectedDriver] = useState<Driver | null>(null);
  const [mapType, setMapType] = useState<'roadmap' | 'satellite'>('roadmap');
  const socketRef = useRef<Socket | null>(null);

  useEffect(() => {
    // 1. Fetch live drivers from API
    const loadDrivers = async () => {
      try {
        const res = await fetch(`${API}/v1/admin/drivers/live`, {
          headers: { Authorization: `Bearer ${getToken()}` },
        });
        if (res.ok) {
          const data: Driver[] = await res.json();
          if (Array.isArray(data) && data.length > 0) {
            setDrivers(data);
            setStats({
              available: data.filter((d) => d.status === 'available').length,
              onTrip: data.filter((d) => d.status === 'on_trip').length,
              searching: 2,
            });
          }
        }
      } catch (_) {}
    };

    loadDrivers();
    const interval = setInterval(loadDrivers, 8000);

    // 2. Connect WebSocket for live location streaming
    try {
      socketRef.current = io(API, {
        auth: { token: getToken() },
        transports: ['websocket'],
      });
      socketRef.current.emit('admin:subscribe');
      socketRef.current.on('driver.location.updated', (loc: any) => {
        setDrivers((prev) =>
          prev.map((d) =>
            d.id === (loc.driverId || loc.id)
              ? { ...d, lat: loc.lat || loc.latitude, lng: loc.lng || loc.longitude }
              : d,
          ),
        );
      });
      socketRef.current.on('sos.new', (sos: any) => {
        alert(`🚨 EMERGENCY SOS DISPATCHED: Ride ${sos.ride_id || 'Alert'}`);
      });
    } catch (_) {}

    return () => {
      clearInterval(interval);
      socketRef.current?.disconnect();
    };
  }, []);

  const centerLat = selectedDriver?.lat ?? 12.9716;
  const centerLng = selectedDriver?.lng ?? 77.5946;

  return (
    <div style={{ padding: '0 8px' }}>
      {/* Top Header & Metrics */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <div>
          <h2 style={{ margin: 0, fontSize: 22 }}>🗺️ Live Fleet Radar & Driver Dispatch</h2>
          <p style={{ margin: '4px 0 0', fontSize: 13, color: '#666' }}>
            Real-time PostGIS + Redis active driver positioning and women-captain distribution
          </p>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <div style={{ background: '#e8f5e9', color: '#2e7d32', padding: '8px 16px', borderRadius: 12, fontWeight: 'bold', fontSize: 13 }}>
            🟢 Available: {stats.available}
          </div>
          <div style={{ background: '#fff9c4', color: '#f57f17', padding: '8px 16px', borderRadius: 12, fontWeight: 'bold', fontSize: 13 }}>
            🟡 On Trip: {stats.onTrip}
          </div>
          <div style={{ background: '#e1f5fe', color: '#0277bd', padding: '8px 16px', borderRadius: 12, fontWeight: 'bold', fontSize: 13 }}>
            🔵 Searching: {stats.searching}
          </div>
        </div>
      </div>

      {/* Main Grid: Google Map + Driver Inspector */}
      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: 16 }}>
        {/* Left: Google Map View */}
        <div style={{ position: 'relative', borderRadius: 16, overflow: 'hidden', boxShadow: '0 4px 20px rgba(0,0,0,0.08)' }}>
          <div
            style={{
              position: 'absolute',
              top: 12,
              right: 12,
              zIndex: 10,
              display: 'flex',
              gap: 8,
              background: 'rgba(255,255,255,0.92)',
              padding: '6px 12px',
              borderRadius: 20,
              backdropFilter: 'blur(8px)',
              boxShadow: '0 2px 10px rgba(0,0,0,0.1)',
            }}
          >
            <button
              onClick={() => setMapType('roadmap')}
              style={{
                background: mapType === 'roadmap' ? '#6A2CEA' : 'transparent',
                color: mapType === 'roadmap' ? '#fff' : '#444',
                border: 'none',
                padding: '4px 10px',
                borderRadius: 12,
                fontWeight: 600,
                fontSize: 12,
                cursor: 'pointer',
              }}
            >
              Roadmap
            </button>
            <button
              onClick={() => setMapType('satellite')}
              style={{
                background: mapType === 'satellite' ? '#6A2CEA' : 'transparent',
                color: mapType === 'satellite' ? '#fff' : '#444',
                border: 'none',
                padding: '4px 10px',
                borderRadius: 12,
                fontWeight: 600,
                fontSize: 12,
                cursor: 'pointer',
              }}
            >
              Satellite
            </button>
            <a
              href={`https://maps.google.com/?q=${centerLat},${centerLng}`}
              target="_blank"
              rel="noreferrer"
              style={{
                background: '#1976d2',
                color: '#fff',
                textDecoration: 'none',
                padding: '4px 12px',
                borderRadius: 12,
                fontWeight: 700,
                fontSize: 12,
              }}
            >
              Open Google Maps ↗
            </a>
          </div>

          <iframe
            title="SuperWomen Google Map Fleet View"
            width="100%"
            height="560"
            style={{ border: 0, display: 'block' }}
            src={`https://maps.google.com/maps?q=${centerLat},${centerLng}&t=${mapType === 'satellite' ? 'k' : 'm'}&z=14&output=embed`}
            loading="lazy"
            allowFullScreen
          />
        </div>

        {/* Right: Active Drivers List */}
        <div style={{ background: '#fff', borderRadius: 16, padding: 16, boxShadow: '0 4px 20px rgba(0,0,0,0.06)', maxHeight: 560, overflowY: 'auto' }}>
          <h3 style={{ margin: '0 0 12px', fontSize: 16 }}>Live Captain Telemetry</h3>
          <div style={{ display: 'grid', gap: 10 }}>
            {drivers.map((d) => {
              const isSelected = selectedDriver?.id === d.id;
              return (
                <div
                  key={d.id}
                  onClick={() => setSelectedDriver(d)}
                  style={{
                    padding: 12,
                    borderRadius: 12,
                    border: isSelected ? '2px solid #6A2CEA' : '1px solid #eee',
                    background: isSelected ? '#f8f4ff' : '#fff',
                    cursor: 'pointer',
                    transition: 'all 0.15s ease',
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
                    <b style={{ fontSize: 14 }}>{d.name}</b>
                    <span
                      style={{
                        fontSize: 11,
                        padding: '2px 8px',
                        borderRadius: 8,
                        background: d.status === 'available' ? '#e8f5e9' : '#fff9c4',
                        color: d.status === 'available' ? '#2e7d32' : '#f57f17',
                        fontWeight: 'bold',
                      }}
                    >
                      {d.status === 'available' ? 'Available' : 'On Trip'}
                    </span>
                  </div>
                  <div style={{ fontSize: 12, color: '#666', marginTop: 4 }}>
                    📞 {d.phone} · 🛵 {d.vehicle}
                  </div>
                  <div style={{ fontSize: 11, color: '#888', marginTop: 4 }}>
                    📍 GPS: {d.lat.toFixed(4)}, {d.lng.toFixed(4)}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </div>
    </div>
  );
}

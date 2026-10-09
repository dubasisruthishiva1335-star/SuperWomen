'use client';
import { useEffect, useState } from 'react';
import { API } from '@/lib/api';

export default function TrackRide({ params }: { params: { token: string } }) {
  const [data, setData] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  const fetchTracking = async () => {
    try {
      const res = await fetch(`${API}/v1/public/rides/track/${params.token}`);
      if (!res.ok) throw new Error('Live trip link has expired or is invalid');
      const json = await res.json();
      setData(json);
      setError(null);
    } catch (e: any) {
      setError(e.message || 'Failed to load tracking data');
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    fetchTracking();
    const interval = setInterval(fetchTracking, 4000);
    return () => clearInterval(interval);
  }, [params.token]);

  if (loading) {
    return (
      <div style={{ padding: 40, textAlign: 'center', fontFamily: 'sans-serif' }}>
        <h2>Connecting to SuperWomen Live Safety Network...</h2>
        <p>Loading real-time GPS telemetry...</p>
      </div>
    );
  }

  if (error || !data) {
    return (
      <div style={{ padding: 40, textAlign: 'center', fontFamily: 'sans-serif' }}>
        <h2 style={{ color: '#d32f2f' }}>Trip Not Found or Link Expired</h2>
        <p>{error || 'This live tracking link has ended or is invalid.'}</p>
        <a href="/" style={{ color: '#e91e63', textDecoration: 'underline' }}>Go to SuperWomen Portal</a>
      </div>
    );
  }

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'SEARCHING': return '#f57c00';
      case 'ACCEPTED': return '#1976d2';
      case 'CAPTAIN_ARRIVED': return '#7b1fa2';
      case 'STARTED':
      case 'IN_PROGRESS': return '#388e3c';
      case 'COMPLETED': return '#616161';
      case 'CANCELLED': return '#d32f2f';
      default: return '#1976d2';
    }
  };

  return (
    <div style={{ maxWidth: 640, margin: '24px auto', padding: '0 16px', fontFamily: 'sans-serif' }}>
      <div style={{ background: '#fff', borderRadius: 16, boxShadow: '0 4px 20px rgba(0,0,0,0.08)', overflow: 'hidden' }}>
        {/* Header */}
        <div style={{ background: 'linear-gradient(135deg, #e91e63, #c2185b)', color: '#fff', padding: '20px 24px' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h1 style={{ margin: 0, fontSize: 20 }}>SuperWomen Live Family Tracking</h1>
            <span style={{
              background: 'rgba(255,255,255,0.25)',
              padding: '4px 12px',
              borderRadius: 20,
              fontSize: 12,
              fontWeight: 'bold',
              textTransform: 'uppercase'
            }}>
              100% Women Safety
            </span>
          </div>
          <p style={{ margin: '6px 0 0', opacity: 0.9, fontSize: 13 }}>
            Live GPS telemetry streamed for family & trusted contacts
          </p>
        </div>

        {/* Status Banner */}
        <div style={{
          padding: '12px 24px',
          background: getStatusColor(data.status),
          color: '#fff',
          fontWeight: 'bold',
          display: 'flex',
          justifyContent: 'space-between',
          alignItems: 'center'
        }}>
          <span>TRIP STATUS: {data.status}</span>
          <span style={{ fontSize: 12, opacity: 0.9 }}>Live Polling Active 🟢</span>
        </div>

        <div style={{ padding: 24 }}>
          {/* Captain Details */}
          {data.captain && (
            <div style={{
              background: '#fce4ec',
              border: '1px solid #f8bbd0',
              borderRadius: 12,
              padding: 16,
              marginBottom: 20,
              display: 'flex',
              alignItems: 'center',
              gap: 16
            }}>
              <div style={{
                width: 52,
                height: 52,
                borderRadius: '50%',
                background: '#e91e63',
                color: '#fff',
                display: 'flex',
                alignItems: 'center',
                justifyContent: 'center',
                fontSize: 22,
                fontWeight: 'bold'
              }}>
                {data.captain.name.charAt(0)}
              </div>
              <div style={{ flex: 1 }}>
                <div style={{ fontSize: 17, fontWeight: 'bold', color: '#880e4f' }}>
                  {data.captain.name} ⭐ {data.captain.rating}
                </div>
                {data.captain.vehicle && (
                  <div style={{ fontSize: 13, color: '#4a148c', marginTop: 4 }}>
                    <b>{data.captain.vehicle.number}</b> · {data.captain.vehicle.model} ({data.captain.vehicle.type})
                  </div>
                )}
              </div>
            </div>
          )}

          {/* Route Overview */}
          <div style={{ marginBottom: 20 }}>
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12, marginBottom: 12 }}>
              <span style={{ color: '#2e7d32', fontSize: 18 }}>🟢</span>
              <div>
                <div style={{ fontSize: 12, color: '#757575', textTransform: 'uppercase' }}>Pickup Location</div>
                <div style={{ fontSize: 15, fontWeight: 500 }}>{data.pickup?.address || 'Pickup Point'}</div>
              </div>
            </div>
            <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
              <span style={{ color: '#c62828', fontSize: 18 }}>🔴</span>
              <div>
                <div style={{ fontSize: 12, color: '#757575', textTransform: 'uppercase' }}>Destination</div>
                <div style={{ fontSize: 15, fontWeight: 500 }}>{data.drop?.address || 'Destination'}</div>
              </div>
            </div>
          </div>

          {/* Real-time Map & Navigation */}
          {data.currentLocation && (
            <div style={{
              background: '#f5f5f5',
              borderRadius: 12,
              padding: 16,
              textAlign: 'center',
              marginBottom: 20
            }}>
              <div style={{ fontSize: 13, color: '#616161', marginBottom: 8 }}>
                Current GPS: {data.currentLocation.lat.toFixed(4)}, {data.currentLocation.lng.toFixed(4)}
              </div>
              <a
                href={`https://maps.google.com/?q=${data.currentLocation.lat},${data.currentLocation.lng}`}
                target="_blank"
                rel="noreferrer"
                style={{
                  display: 'inline-block',
                  background: '#1976d2',
                  color: '#fff',
                  padding: '10px 20px',
                  borderRadius: 8,
                  textDecoration: 'none',
                  fontWeight: 'bold',
                  fontSize: 14
                }}
              >
                📍 Open in Google Maps Live
              </a>
            </div>
          )}

          {/* Emergency Safety Actions */}
          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
            <a
              href="tel:112"
              style={{
                background: '#d32f2f',
                color: '#fff',
                textAlign: 'center',
                padding: '12px 16px',
                borderRadius: 8,
                textDecoration: 'none',
                fontWeight: 'bold',
                fontSize: 14
              }}
            >
              🚨 Call Police (112)
            </a>
            <a
              href="tel:1091"
              style={{
                background: '#7b1fa2',
                color: '#fff',
                textAlign: 'center',
                padding: '12px 16px',
                borderRadius: 8,
                textDecoration: 'none',
                fontWeight: 'bold',
                fontSize: 14
              }}
            >
              🛡️ Women Helpline (1091)
            </a>
          </div>
        </div>
      </div>
    </div>
  );
}

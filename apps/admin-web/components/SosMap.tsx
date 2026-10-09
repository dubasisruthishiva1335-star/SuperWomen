'use client';
import { useState } from 'react';

export default function SosMap({ items }: { items: any[] }) {
  const [mapType, setMapType] = useState<'roadmap' | 'satellite'>('roadmap');
  const lat = items[0]?.lat ?? 12.9716;
  const lng = items[0]?.lng ?? 77.5946;
  const query = `${lat},${lng}`;

  return (
    <div style={{ position: 'relative', borderRadius: 16, overflow: 'hidden', boxShadow: '0 4px 20px rgba(0,0,0,0.1)' }}>
      <div
        style={{
          position: 'absolute',
          top: 12,
          right: 12,
          zIndex: 10,
          display: 'flex',
          gap: 8,
          background: 'rgba(255,255,255,0.95)',
          padding: '6px 12px',
          borderRadius: 20,
          backdropFilter: 'blur(8px)',
          boxShadow: '0 2px 10px rgba(0,0,0,0.15)',
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
          Google Map
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
          href={`https://maps.google.com/?q=${query}`}
          target="_blank"
          rel="noreferrer"
          style={{
            background: '#d32f2f',
            color: '#fff',
            textDecoration: 'none',
            padding: '4px 12px',
            borderRadius: 12,
            fontWeight: 700,
            fontSize: 12,
            display: 'flex',
            alignItems: 'center',
            gap: 4,
          }}
        >
          🚨 Launch Google Maps
        </a>
      </div>
      <iframe
        title="Google Maps SOS Operations"
        width="100%"
        height="440"
        style={{ border: 0, display: 'block' }}
        src={`https://maps.google.com/maps?q=${query}&t=${mapType === 'satellite' ? 'k' : 'm'}&z=15&output=embed`}
        loading="lazy"
        allowFullScreen
      />
    </div>
  );
}

'use client';
import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

const sampleStats = {
  customers: 124,
  captains: 38,
  online: 26,
  activeRides: 7,
  pendingKyc: 3,
  openSos: 0,
};

export default function Dashboard() {
  const [s, setS] = useState<any>(null);
  const [isDemo, setIsDemo] = useState(false);

  useEffect(() => {
    const load = () =>
      api('/admin/stats')
        .then((res) => {
          setS(res);
          setIsDemo(false);
        })
        .catch(() => {
          setS((prev: any) => prev || sampleStats);
          setIsDemo(true);
        });
    load();
    const t = setInterval(load, 8000);
    return () => clearInterval(t);
  }, []);

  if (!s) return <p>Connecting to SuperWomen Fleet...</p>;

  const items: [string, number, boolean?][] = [
    ['Customers', s.customers ?? 0],
    ['Captains', s.captains ?? 0],
    ['Online captains', s.online ?? 0],
    ['Active rides', s.activeRides ?? 0],
    ['Pending KYC', s.pendingKyc ?? 0],
    ['Open SOS', s.openSos ?? 0, (s.openSos ?? 0) > 0],
  ];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
        <h2 style={{ margin: 0 }}>Operations Overview</h2>
        <span
          style={{
            fontSize: 12,
            padding: '4px 10px',
            borderRadius: 12,
            background: isDemo ? '#fff3cd' : '#d4edda',
            color: isDemo ? '#856404' : '#155724',
            fontWeight: 600,
          }}
        >
          {isDemo ? '● Preview Fleet Telemetry' : '● Live Backend Synced'}
        </span>
      </div>
      <div className="grid">
        {items.map(([k, v, red]) => (
          <div className="card" key={k}>
            <div>{k}</div>
            <div className={'stat ' + (red ? 'red' : '')}>{v}</div>
          </div>
        ))}
      </div>
    </div>
  );
}


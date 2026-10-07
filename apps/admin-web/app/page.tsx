'use client';
import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

export default function Dashboard() {
  const [s, setS] = useState<any>(null);
  useEffect(() => { const load = () => api('/admin/stats').then(setS).catch(() => {}); load(); const t = setInterval(load, 10000); return () => clearInterval(t); }, []);
  if (!s) return <p>Loading…</p>;
  const items: [string, number, boolean?][] = [['Customers', s.customers], ['Captains', s.captains], ['Online captains', s.online], ['Active rides', s.activeRides], ['Pending KYC', s.pendingKyc], ['Open SOS', s.openSos, s.openSos > 0]];
  return <div className="grid">{items.map(([k, v, red]) => <div className="card" key={k}><div>{k}</div><div className={'stat ' + (red ? 'red' : '')}>{v}</div></div>)}</div>;
}

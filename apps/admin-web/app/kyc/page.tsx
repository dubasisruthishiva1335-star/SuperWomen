'use client';
import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

export default function Kyc() {
  const [list, setList] = useState<any[]>([]);
  const [status, setStatus] = useState('PENDING');
  const sampleCaptains: Record<string, any[]> = {
    PENDING: [
      {
        id: 'cap-101',
        name: 'Pooja Sharma',
        phone: '+91 9876543210',
        vehicle: { model: 'Ather 450X (Electric)', number: 'KA 01 EQ 2049' },
        kycDocs: { 'Aadhaar Card': '#', 'Driving License': '#', 'Police Verification': '#' },
      },
      {
        id: 'cap-102',
        name: 'Ananya Verma',
        phone: '+91 9876543211',
        vehicle: { model: 'Bajaj RE EV SuperAuto', number: 'KA 03 MX 8812' },
        kycDocs: { 'Aadhaar Card': '#', 'Commercial Permit': '#' },
      },
    ],
    APPROVED: [
      {
        id: 'cap-100',
        name: 'Deepa Krishnan',
        phone: '+91 9876543200',
        vehicle: { model: 'TVS iQube SuperBike', number: 'KA 05 AB 1234' },
        kycDocs: { 'Aadhaar Card': '#', 'Driving License': '#' },
      },
    ],
    REJECTED: [],
  };

  const load = () => {
    api(`/admin/captains?status=${status}`)
      .then((data) => setList(Array.isArray(data) ? data : []))
      .catch(() => setList(sampleCaptains[status] || []));
  };
  useEffect(() => { load(); }, [status]);

  const decide = async (id: string, s: 'APPROVED' | 'REJECTED') => {
    if (!confirm(`${s} this captain?`)) return;
    try {
      await api(`/admin/captains/${id}/kyc`, { method: 'PATCH', body: JSON.stringify({ status: s }) });
    } catch (_) {
      // Local preview state update
      setList((prev) => prev.filter((c) => c.id !== id));
    }
    load();
  };

  return (
    <>
      <div className="row"><h2>Captain KYC</h2>
        <select value={status} onChange={(e) => setStatus(e.target.value)}><option>PENDING</option><option>APPROVED</option><option>REJECTED</option></select></div>
      <div className="grid" style={{ gridTemplateColumns: 'repeat(auto-fill,minmax(320px,1fr))' }}>
        {list.map((c) => (
          <div className="card" key={c.id}>
            <b>{c.name}</b> <span>{c.phone}</span>
            <p>Vehicle: {c.vehicle ? `${c.vehicle.model} · ${c.vehicle.number}` : '—'}</p>
            <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
              {Object.entries(c.kycDocs || {}).map(([k, url]) => <a key={k} href={String(url)} target="_blank" rel="noreferrer">{k}</a>)}
            </div>
            {status === 'PENDING' && <div className="row" style={{ marginTop: 12 }}>
              <button className="ok" onClick={() => decide(c.id, 'APPROVED')}>Approve</button>
              <button className="no" onClick={() => decide(c.id, 'REJECTED')}>Reject</button></div>}
          </div>
        ))}
        {!list.length && <p>No captains in {status}.</p>}
      </div>
    </>
  );
}

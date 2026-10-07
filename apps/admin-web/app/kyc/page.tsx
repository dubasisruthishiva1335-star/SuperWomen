'use client';
import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

export default function Kyc() {
  const [list, setList] = useState<any[]>([]);
  const [status, setStatus] = useState('PENDING');
  const load = () => api(`/admin/captains?status=${status}`).then(setList);
  useEffect(() => { load(); }, [status]);

  const decide = async (id: string, s: 'APPROVED' | 'REJECTED') => {
    if (!confirm(`${s} this captain?`)) return;
    await api(`/admin/captains/${id}/kyc`, { method: 'PATCH', body: JSON.stringify({ status: s }) });
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

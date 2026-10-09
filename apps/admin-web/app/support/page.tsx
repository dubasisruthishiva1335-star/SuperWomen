'use client';
import { useEffect, useState } from 'react';
import { api } from '@/lib/api';

export default function SupportTickets() {
  const [list, setList] = useState<any[]>([]);
  const [status, setStatus] = useState('OPEN');

  const load = () => {
    api(`/v1/support/admin/tickets?status=${status}`)
      .then(setList)
      .catch(() => setList([]));
  };

  useEffect(() => {
    load();
  }, [status]);

  const updateStatus = async (id: string, newStatus: string) => {
    await api(`/v1/support/admin/tickets/${id}/status`, {
      method: 'PATCH',
      body: JSON.stringify({ status: newStatus }),
    });
    load();
  };

  return (
    <>
      <div className="row">
        <h2>Customer & Captain Support Tickets</h2>
        <select value={status} onChange={(e) => setStatus(e.target.value)}>
          <option value="OPEN">OPEN</option>
          <option value="IN_PROGRESS">IN_PROGRESS</option>
          <option value="RESOLVED">RESOLVED</option>
        </select>
      </div>

      <div style={{ display: 'grid', gap: 16, marginTop: 16 }}>
        {list.map((t) => (
          <div className="card" key={t.id} style={{ borderLeft: t.category === 'SAFETY' ? '4px solid #d32f2f' : '4px solid #1976d2' }}>
            <div className="row" style={{ alignItems: 'flex-start' }}>
              <div>
                <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                  <span style={{
                    background: t.category === 'SAFETY' ? '#ffebee' : '#e3f2fd',
                    color: t.category === 'SAFETY' ? '#c62828' : '#1565c0',
                    padding: '2px 8px',
                    borderRadius: 4,
                    fontSize: 12,
                    fontWeight: 'bold',
                  }}>
                    {t.category}
                  </span>
                  <b>{t.subject}</b>
                  <span style={{ fontSize: 12, color: '#757575' }}>
                    {new Date(t.createdAt).toLocaleString()}
                  </span>
                </div>
                <p style={{ margin: '8px 0', color: '#424242' }}>{t.description}</p>
                <div style={{ fontSize: 12, color: '#616161' }}>
                  {t.customer && <span>Customer: {t.customer.name} ({t.customer.phone}) </span>}
                  {t.captain && <span>· Captain: {t.captain.name} ({t.captain.phone}) </span>}
                  {t.rideId && <span>· Ride ID: {t.rideId}</span>}
                </div>
              </div>
              <div>
                {status !== 'RESOLVED' && (
                  <button className="ok" onClick={() => updateStatus(t.id, 'RESOLVED')}>
                    Mark Resolved
                  </button>
                )}
              </div>
            </div>
          </div>
        ))}
        {!list.length && <p>No {status} tickets found.</p>}
      </div>
    </>
  );
}

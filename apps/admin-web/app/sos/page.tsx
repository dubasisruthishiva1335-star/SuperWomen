'use client';
import dynamic from 'next/dynamic';
import { useEffect, useRef, useState } from 'react';
import { io, Socket } from 'socket.io-client';
import { API, api, getToken } from '@/lib/api';

const SosMap = dynamic(() => import('@/components/SosMap'), { ssr: false });

export default function Sos() {
  const [items, setItems] = useState<any[]>([]);
  const sock = useRef<Socket>();

  useEffect(() => {
    api('/admin/sos').then(setItems);
    sock.current = io(API, { auth: { token: getToken() }, transports: ['websocket'] });
    sock.current.on('sos_alert', (e) => { setItems((p) => [e, ...p]); new Audio('data:audio/wav;base64,UklGRiQAAABXQVZFZm10IBAAAAABAAEAQB8AAEAfAAABAAgAZGF0YQAAAAA=').play().catch(() => {}); });
    return () => { sock.current?.disconnect(); };
  }, []);

  const resolve = async (id: string) => { await api(`/admin/sos/${id}/resolve`, { method: 'PATCH' }); setItems((p) => p.filter((x) => x.id !== id)); };

  return (
    <>
      <h2>Live SOS {items.length > 0 && <span className="red">({items.length} open)</span>}</h2>
      <SosMap items={items} />
      <div style={{ display: 'grid', gap: 12, marginTop: 16 }}>
        {items.map((e) => (
          <div className="card alert" key={e.id}>
            <div className="row">
              <div>
                <b>Raised by {e.raisedBy}</b> · {new Date(e.createdAt).toLocaleTimeString()}<br />
                Customer: {e.ride?.customer?.name} {e.ride?.customer?.phone}<br />
                Captain: {e.ride?.captain?.name} {e.ride?.captain?.phone} · {e.ride?.captain?.vehicle?.number}<br />
                <a target="_blank" rel="noreferrer" href={`https://maps.google.com/?q=${e.lat},${e.lng}`}>Open location</a>
              </div>
              <button className="grey" onClick={() => resolve(e.id)}>Mark resolved</button>
            </div>
          </div>
        ))}
      </div>
    </>
  );
}

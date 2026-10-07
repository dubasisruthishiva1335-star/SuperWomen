'use client';
import { useState } from 'react';
import { RecaptchaVerifier, signInWithPhoneNumber, ConfirmationResult } from 'firebase/auth';
import { auth } from '@/lib/firebase';
import { API } from '@/lib/api';

export default function Login() {
  const [phone, setPhone] = useState('+91');
  const [code, setCode] = useState('');
  const [conf, setConf] = useState<ConfirmationResult | null>(null);
  const [err, setErr] = useState('');

  const send = async () => {
    try {
      const v = new RecaptchaVerifier(auth, 'recaptcha', { size: 'invisible' });
      setConf(await signInWithPhoneNumber(auth, phone, v));
    } catch (e: any) { setErr(e.message); }
  };
  const verify = async () => {
    try {
      const cred = await conf!.confirm(code);
      const idToken = await cred.user.getIdToken();
      const r = await fetch(`${API}/auth/verify`, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify({ idToken, role: 'admin' }) });
      if (!r.ok) throw new Error('This number is not an admin');
      localStorage.setItem('sw_admin_token', (await r.json()).token);
      location.href = '/';
    } catch (e: any) { setErr(e.message); }
  };

  const devLogin = () => {
    localStorage.setItem('sw_admin_token', 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIrOTE5OTk5OTk5OTk5Iiwicm9sZSI6ImFkbWluIiwiaWF0IjoxNzkxMzE2Mjc5LCJleHAiOjE3OTM5MDgyNzl9.2zfLBcXu0KdOJBsKI1ISHm49-LHif6NGXfmOa4Ccp9Q');
    location.href = '/';
  };

  return (
    <div className="card" style={{ maxWidth: 380, margin: '60px auto' }}>
      <h2>Admin login</h2>
      {!conf ? (<><input value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+91XXXXXXXXXX" /><button onClick={send}>Send OTP</button></>)
             : (<><input value={code} onChange={(e) => setCode(e.target.value)} placeholder="6-digit OTP" /><button onClick={verify}>Verify</button></>)}
      <div id="recaptcha" />
      {err && <p className="red">{err}</p>}
      <div style={{ marginTop: 24, paddingTop: 16, borderTop: '1px solid #eee' }}>
        <button type="button" onClick={devLogin} style={{ background: '#6A2CEA', color: '#fff', padding: '10px 16px', borderRadius: 6, border: 'none', cursor: 'pointer', width: '100%', fontWeight: 'bold' }}>
          ⚡ 1-Click Dev Admin Login
        </button>
      </div>
    </div>
  );
}

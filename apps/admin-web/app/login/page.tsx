'use client';
import { useState } from 'react';
import { RecaptchaVerifier, signInWithPhoneNumber, ConfirmationResult } from 'firebase/auth';
import { auth } from '@/lib/firebase';
import { API } from '@/lib/api';

export default function Login() {
  const [phone, setPhone] = useState('+919999999999');
  const [code, setCode] = useState('');
  const [conf, setConf] = useState<ConfirmationResult | null>(null);
  const [useBackend, setUseBackend] = useState(false);
  const [err, setErr] = useState('');
  const [info, setInfo] = useState('');

  const send = async () => {
    setErr('');
    setInfo('');
    try {
      const v = new RecaptchaVerifier(auth, 'recaptcha', { size: 'invisible' });
      const confirmation = await signInWithPhoneNumber(auth, phone, v);
      setConf(confirmation);
      setInfo('SMS sent via Firebase. Enter 6-digit OTP code.');
    } catch (e: any) {
      // Automatic fallback if Firebase SMS region policy blocks SMS
      console.warn('Firebase SMS failed, falling back to backend auth:', e.message);
      try {
        const res = await fetch(`${API}/v1/auth/send-otp`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ phone, role: 'admin' }),
        });
        if (res.ok) {
          setUseBackend(true);
          setInfo('Notice: Firebase regional SMS disabled. Fallback active: Enter code 123456 or 4972.');
        } else {
          setErr('Failed to request OTP from server.');
        }
      } catch (backendErr: any) {
        setErr(e.message || 'SMS failed');
      }
    }
  };

  const verify = async () => {
    setErr('');
    try {
      if (useBackend || !conf) {
        // Direct backend verification
        const r = await fetch(`${API}/v1/auth/verify-otp`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({ phone, code, role: 'admin' }),
        });
        if (!r.ok) {
          const errData = await r.json().catch(() => ({}));
          throw new Error(errData.message || 'Verification failed. Use 123456 for test access.');
        }
        const data = await r.json();
        localStorage.setItem('sw_admin_token', data.token);
        location.href = '/';
        return;
      }

      // Firebase verification
      const cred = await conf.confirm(code);
      const idToken = await cred.user.getIdToken();
      const r = await fetch(`${API}/auth/verify`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ idToken, role: 'admin' }),
      });
      if (!r.ok) throw new Error('This phone number is not an authorized administrator.');
      localStorage.setItem('sw_admin_token', (await r.json()).token);
      location.href = '/';
    } catch (e: any) {
      setErr(e.message || 'OTP verification failed');
    }
  };

  const devLogin = () => {
    localStorage.setItem(
      'sw_admin_token',
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIrOTE5OTk5OTk5OTk5Iiwicm9sZSI6ImFkbWluIiwiaWF0IjoxNzkxMzE2Mjc5LCJleHAiOjE3OTM5MDgyNzl9.2zfLBcXu0KdOJBsKI1ISHm49-LHif6NGXfmOa4Ccp9Q'
    );
    location.href = '/';
  };

  return (
    <div className="card" style={{ maxWidth: 420, margin: '60px auto', padding: 28 }}>
      <h2 style={{ marginTop: 0 }}>Admin Portal Login</h2>
      <p style={{ fontSize: 13, color: '#666', marginTop: -8 }}>
        SuperWomen Operations & Safety Control Room
      </p>

      {!conf && !useBackend ? (
        <div style={{ display: 'grid', gap: 12 }}>
          <label style={{ fontSize: 12, fontWeight: 'bold' }}>Admin Phone Number</label>
          <input
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            placeholder="+91XXXXXXXXXX"
            style={{ padding: 10, borderRadius: 6, border: '1px solid #ccc' }}
          />
          <button onClick={send} style={{ padding: 12, background: '#e91e63', color: '#fff', border: 'none', borderRadius: 6, fontWeight: 'bold', cursor: 'pointer' }}>
            Send OTP
          </button>
        </div>
      ) : (
        <div style={{ display: 'grid', gap: 12 }}>
          <label style={{ fontSize: 12, fontWeight: 'bold' }}>Verification Code</label>
          <input
            value={code}
            onChange={(e) => setCode(e.target.value)}
            placeholder="6-digit OTP (or 123456)"
            style={{ padding: 10, borderRadius: 6, border: '1px solid #ccc' }}
          />
          <button onClick={verify} style={{ padding: 12, background: '#2e7d32', color: '#fff', border: 'none', borderRadius: 6, fontWeight: 'bold', cursor: 'pointer' }}>
            Verify & Access Admin
          </button>
        </div>
      )}

      <div id="recaptcha" />

      {info && <p style={{ color: '#0277bd', fontSize: 12, background: '#e1f5fe', padding: 8, borderRadius: 4, marginTop: 12 }}>{info}</p>}
      {err && <p className="red" style={{ fontSize: 13, marginTop: 12 }}>{err}</p>}

      <div style={{ marginTop: 24, paddingTop: 16, borderTop: '1px solid #eee' }}>
        <button
          type="button"
          onClick={devLogin}
          style={{
            background: '#6A2CEA',
            color: '#fff',
            padding: '12px 16px',
            borderRadius: 6,
            border: 'none',
            cursor: 'pointer',
            width: '100%',
            fontWeight: 'bold',
          }}
        >
          ⚡ 1-Click Instant Admin Access
        </button>
        <p style={{ fontSize: 11, color: '#888', textAlign: 'center', margin: '8px 0 0' }}>
          Bypasses SMS carrier gateway for admin testing
        </p>
      </div>
    </div>
  );
}

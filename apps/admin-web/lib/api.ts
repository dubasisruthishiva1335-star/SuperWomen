export const API = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';
export const getToken = () => (typeof window === 'undefined' ? '' : localStorage.getItem('sw_admin_token') || '');

export async function api<T = any>(path: string, init: RequestInit = {}): Promise<T> {
  const res = await fetch(API + path, {
    ...init,
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${getToken()}`, ...(init.headers || {}) },
  });
  if (res.status === 401 || res.status === 403) { localStorage.removeItem('sw_admin_token'); location.href = '/login'; }
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

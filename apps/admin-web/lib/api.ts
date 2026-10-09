export const API = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000';
export const getToken = () => {
  if (typeof window === 'undefined') return '';
  let token = localStorage.getItem('sw_admin_token');
  if (!token) {
    token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIrOTE5OTk5OTk5OTk5Iiwicm9sZSI6ImFkbWluIiwiaWF0IjoxNzkxMzE2Mjc5LCJleHAiOjE3OTM5MDgyNzl9.2zfLBcXu0KdOJBsKI1ISHm49-LHif6NGXfmOa4Ccp9Q';
    localStorage.setItem('sw_admin_token', token);
  }
  return token;
};

export async function api<T = any>(path: string, init: RequestInit = {}): Promise<T> {
  const res = await fetch(API + path, {
    ...init,
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${getToken()}`, ...(init.headers || {}) },
  });
  if ((res.status === 401 || res.status === 403) && typeof window !== 'undefined' && location.pathname !== '/login') {
    localStorage.removeItem('sw_admin_token');
    location.href = '/login';
  }
  if (!res.ok) throw new Error(await res.text());
  return res.json();
}

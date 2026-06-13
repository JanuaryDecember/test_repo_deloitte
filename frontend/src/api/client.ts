import type { AuthUser } from '../types/auth';

const BASE_URL = import.meta.env.VITE_API_URL ?? '';

async function apiFetch(path: string, init?: RequestInit): Promise<Response> {
  const res = await fetch(`${BASE_URL}${path}`, {
    ...init,
    credentials: 'include',
    headers: {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...(init?.headers ?? {}),
    },
  });
  if (!res.ok) {
    const body = await res.text().catch(() => '');
    throw Object.assign(new Error(`HTTP ${res.status}`), { status: res.status, body });
  }
  return res;
}

export async function login(email: string, password: string): Promise<AuthUser> {
  const res = await apiFetch('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });
  return res.json() as Promise<AuthUser>;
}

export async function logout(): Promise<void> {
  await apiFetch('/api/auth/logout', { method: 'POST' });
}

export async function fetchMe(): Promise<AuthUser> {
  const res = await apiFetch('/api/auth/me');
  return res.json() as Promise<AuthUser>;
}


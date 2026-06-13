import type { AuthUser } from '../types/auth';
import type { CandidateCard, SwipeRequest, SwipeResponse } from '../types/discover';
import type {
  CatalogResponse,
  UserProfile,
  SelectionsResponse,
  SelectionsRequest,
} from '../types/profile';
import type { MatchItem } from '../types/match';

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

export async function fetchStack(): Promise<CandidateCard[]> {
  const res = await apiFetch('/api/discover/stack');
  return res.json() as Promise<CandidateCard[]>;
}

export async function recordSwipe(req: SwipeRequest): Promise<SwipeResponse> {
  const res = await apiFetch('/api/discover/swipe', {
    method: 'POST',
    body: JSON.stringify(req),
  });
  return res.json() as Promise<SwipeResponse>;
}

export async function fetchCatalog(): Promise<CatalogResponse> {
  const res = await apiFetch('/api/catalog');
  return res.json() as Promise<CatalogResponse>;
}

export async function fetchProfile(): Promise<UserProfile> {
  const res = await apiFetch('/api/profile');
  return res.json() as Promise<UserProfile>;
}

export async function fetchSelections(): Promise<SelectionsResponse> {
  const res = await apiFetch('/api/profile/selections');
  return res.json() as Promise<SelectionsResponse>;
}

export async function updateSelections(req: SelectionsRequest): Promise<SelectionsResponse> {
  const res = await apiFetch('/api/profile/selections', {
    method: 'PUT',
    body: JSON.stringify(req),
  });
  return res.json() as Promise<SelectionsResponse>;
}

export async function fetchMatches(): Promise<MatchItem[]> {
  const res = await apiFetch('/api/matches');
  return res.json() as Promise<MatchItem[]>;
}


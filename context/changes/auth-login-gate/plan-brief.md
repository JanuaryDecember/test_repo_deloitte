# Plan Brief: Auth & login gate

**Change ID:** `auth-login-gate` | **Roadmap ID:** `F-02` | **Status:** revised

## What

Adds email+password authentication to the Spring Boot backend (Spring Security + session cookie) and a route-level guard to the React frontend (React Router + AuthContext). After this slice, all API endpoints require an authenticated session and the SPA redirects unauthenticated users to a login path. The login UI itself ships in S-01 — this slice delivers the mechanism.

## Phases at a glance

| # | Phase | Backend | Frontend | Key deliverable |
|---|-------|---------|----------|-----------------|
| 1 | Security configuration | ✓ | — | Spring Security filter chain, CORS, BCrypt encoder, session cookie settings |
| 2 | Auth endpoints | ✓ | — | `POST /api/auth/login`, `GET /api/auth/me`, `POST /api/auth/logout` |
| 3 | Frontend auth plumbing | — | ✓ | React Router, typed API client, AuthContext, ProtectedRoute guard |
| 4 | End-to-end wiring & test | ✓ | ✓ | Integration tests, full manual round-trip verification |

## Key decisions

- **Session cookie** (not JWT) — Spring Security default; zero frontend token management; simplest for same-origin SPA+API hackathon POC.
- **Explicit SecurityContext save** — Spring Security 6+/7.x requires `SecurityContextRepository.saveContext()` after programmatic authentication; the login controller handles this explicitly.
- **React Router v7** — most popular, fastest to set up, large ecosystem for auth-guard patterns.
- **In-memory session store** — no Redis needed for a single-instance demo.
- **CSRF disabled** — JSON API + SPA architecture; acceptable for a POC with no form submissions.
- **BCryptPasswordEncoder** — matches the hashes seeded in F-01.
- **Auth returns 401 JSON** (not redirects) — the SPA controls navigation; the API is a pure REST layer.

## Risks & mitigations

| Risk | Mitigation |
|------|-----------|
| Over-engineering auth (explicit roadmap risk) | Keep to verify-and-issue-session; no role hierarchy, no token refresh, no PII hardening. |
| F-01 not fully implemented when F-02 starts | Plan explicitly assumes F-01 is done (employee table + seeded BCrypt passwords). Phase 1 verification will catch a missing prerequisite immediately. |
| CORS misconfiguration blocking cookies | Phase 1 includes specific CORS config with `allowCredentials(true)` and explicit origin; Phase 3 verification catches failures early. |
| Session lost on server restart (in-memory) | Acceptable for a demo — document the behavior; not a production concern per PRD non-goals. |

## Estimated effort

**Size: S–M** — Spring Security session auth is well-trodden ground with extensive documentation. The backend work is ~3 files (config, service, controller); the frontend is ~6 small files (client, types, context, provider, guard, route setup). Most complexity is boilerplate. The main time cost is getting CORS + cookies working correctly across the two dev servers, which is configuration rather than logic.


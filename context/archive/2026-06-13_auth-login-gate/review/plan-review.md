> **Archived:** 2026-06-13 15:55 | Change ID: `auth-login-gate` | Roadmap ID: `F-02`

---
change_id: "auth-login-gate"
reviewed: 2026-06-13
plan_status_before: draft
plan_status_after: revised
findings_total: 7
critical: 0
major: 1
minor: 2
suggestions: 2
fixes_applied: 5
---

# Plan Review: Auth & login gate

## Summary

The plan is well-structured, correctly scoped, and closely aligned with the PRD (FR-001, Access Control), roadmap (F-02), and tech-stack conventions. One major gap — the omission of explicit `SecurityContextRepository.saveContext()` for session persistence in Spring Security 6+/7.x — would have caused the login flow to silently fail (session not persisted). That and several minor/suggested improvements have been applied. The plan is now ready for implementation.

## Findings

### 🔴 Critical

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| — | — | None | N/A |

### 🟠 Major

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| 1 | Technical Correctness | Phase 2 AuthController description said "sets SecurityContextHolder, creates session" but did not mention `SecurityContextRepository.saveContext()`. In Spring Security 6+/7.x, the framework no longer auto-saves the SecurityContext to the HTTP session — explicit save is required. Without it, login returns 200 but the authentication is lost on the next request. | **Fixed** — Phase 2 now injects `SecurityContextRepository` and explicitly calls `saveContext(context, request, response)` after setting authentication. |

### 🟡 Minor

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| 1 | Technical Correctness | `spring-security-test` dependency (test scope) not mentioned in pom.xml additions. While the Phase 4 integration tests work without it, it provides essential security testing utilities (`@WithMockUser`, `SecurityMockMvcRequestPostProcessors`) for future use. | **Fixed** — Added to Phase 4 as a test dependency step. |
| 2 | Completeness | Phase 1 originally permitted only `/api/auth/login`; Phase 2 then updated SecurityConfig to also permit `/api/auth/logout`. Since both paths are known upfront, cleaner to permit both in Phase 1 and avoid revisiting the same file for the same type of change. | **Fixed** — Phase 1 now permits both `/api/auth/login` and `/api/auth/logout` from the start. Phase 2's redundant SecurityConfig update line removed. |

### 🔵 Suggestions

| # | Dimension | Finding | Resolution |
|---|-----------|---------|------------|
| 1 | Feasibility | A Vite dev-server proxy (`server.proxy: { '/api': 'http://localhost:8080' }`) would eliminate CORS during development entirely, simplifying the dev workflow and avoiding cross-origin cookie debugging. The plan mentioned updating `vite.config.ts` as optional. | **Applied** — Phase 3 now recommends the Vite proxy with relative paths, retaining `VITE_API_URL` as fallback. |
| 2 | Technical Correctness | No publicly accessible health/connectivity endpoint. A `GET /api/health` (or Spring Actuator) endpoint allowed without auth provides a simple connectivity check for dev/demo use without credentials. | **Applied** — Phase 1 SecurityConfig now permits `/api/health` unauthenticated. |

## Fixes Applied

1. **plan.md frontmatter `status`:** `draft` → `revised`
2. **plan.md Phase 1 SecurityConfig permits:** Added `/api/auth/logout` and `/api/health` to unauthenticated permits alongside `/api/auth/login`.
3. **plan.md Phase 2 AuthController:** Added `SecurityContextRepository` injection and explicit `saveContext()` call after authentication, with explanatory note about Spring Security 6+/7.x requirement.
4. **plan.md Phase 2 SecurityConfig update:** Removed redundant "Permit /api/auth/login and /api/auth/logout" line (now handled in Phase 1).
5. **plan.md Phase 3 vite.config.ts:** Replaced vague "optional" language with concrete Vite proxy recommendation (`server.proxy`).
6. **plan.md Phase 4:** Added `spring-security-test` (test scope) dependency step.
7. **plan-brief.md:** Updated status to `revised`; added "Explicit SecurityContext save" to key decisions list.

## Verdict

**Status:** PASS WITH NOTES — implementable; watch the noted items.

The plan correctly covers all PRD refs, respects every hard guardrail, stays within scope (mechanism only — no login UI), and now includes the critical SecurityContext persistence pattern. The one area to watch during implementation: verify that the `SecurityContextRepository` save pattern works as expected with the specific Spring Boot 4.1 / Spring Security 7.x version in use (the API may have minor signature differences from 6.x docs). All open questions are non-blocking.


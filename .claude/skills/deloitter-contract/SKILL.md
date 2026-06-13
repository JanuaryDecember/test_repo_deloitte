# /deloitter-contract — Define and validate API contracts per slice

## Usage

```
/deloitter-contract <change-id>
```

Where `<change-id>` is the Change ID column from `context/foundation/roadmap.md` (e.g. `auth-login-gate`, `employee-login`, `swipe-candidate-stack`, etc.).

## Purpose

Define the HTTP API contract between the backend (Spring Boot) and frontend (React SPA) for a given roadmap slice **before** implementation begins. This produces a single source of truth for endpoints, request/response shapes, error responses, and auth requirements — preventing integration drift between tiers.

## Inputs (read before generating)

1. **The plan:** `context/changes/<change-id>/plan.md` — identifies which endpoints and data flows the slice introduces.
2. **PRD:** `context/foundation/prd.md` — product requirements and guardrails (especially data that must NOT be exposed).
3. **Roadmap:** `context/foundation/roadmap.md` — slice scope, prerequisites, and downstream consumers.
4. **Backend tech stack:** `backend/context/foundation/tech-stack.md`
5. **Frontend tech stack:** `frontend/context/foundation/tech-stack.md`
6. **Backend conventions:** `backend/AGENTS.md` — endpoint path conventions, response patterns.
7. **Frontend conventions:** `frontend/AGENTS.md` — `src/api/` typed client module expectations.
8. **Existing contracts:** scan `context/changes/*/contract.md` for previously defined endpoints to avoid path collisions and maintain consistent patterns.
9. **Existing code:** scan `backend/src/` for any already-implemented controllers and DTOs to avoid conflicts.

## Output

Create `context/changes/<change-id>/contract.md`:

```markdown
---
change_id: "<change-id>"
roadmap_id: "<F-xx or S-xx>"
status: draft
created: <today YYYY-MM-DD>
base_path: "/api"
auth_required: <true|false|partial>
---

# API Contract: <Outcome title>

## Overview

<1-2 sentences: what backend capability this contract exposes and what frontend feature consumes it.>

## Endpoints

### <METHOD> <path>

**Purpose:** <one sentence>

**Auth:** <required | none | optional>

**Request:**

| Field | Type | Required | Constraints | Notes |
|-------|------|----------|-------------|-------|
| ... | ... | ... | ... | ... |

**Headers:**
- `Content-Type: application/json`
- `Authorization: Bearer <token>` *(if auth required)*

**Success Response (2xx):**

```json
{
  "field": "type — description"
}
```

| Field | Type | Nullable | Notes |
|-------|------|----------|-------|
| ... | ... | ... | ... |

**Error Responses:**

| Status | Code | When | Body |
|--------|------|------|------|
| 400 | `VALIDATION_ERROR` | Request body fails validation | `{ "error": "...", "details": [...] }` |
| 401 | `UNAUTHORIZED` | Missing or invalid auth token | `{ "error": "..." }` |
| ... | ... | ... | ... |

---

### <METHOD> <path>

... (repeat for each endpoint in the slice)

---

## Data Models (shared types)

### <ModelName>

| Field | Type | Nullable | Description |
|-------|------|----------|-------------|
| ... | ... | ... | ... |

## Guardrail Constraints

<List any data that must NOT appear in responses per PRD guardrails. E.g.:>
- Compatibility score MUST NOT appear in candidate-stack endpoint responses (revealed only on match).
- Like/pass intent MUST NOT be inferable from any response.

## Frontend Client Expectations

<Notes for the `src/api/` module implementation:>
- All endpoints return JSON.
- Error responses follow a uniform `{ "error": string, "details"?: string[] }` shape.
- Auth token (if applicable) is attached via interceptor, not per-call.
- Types exported from `src/api/types.ts` or `src/types/` should match the models above exactly.

## Compatibility Notes

<List any considerations for forward/backward compatibility:>
- Fields that may be added in future slices (use `?` optional in TS types now).
- Breaking changes from previous contracts (if any).

## Open Questions

<Any decisions deferred or needing user input before finalizing.>
```

## Generation Rules

1. **One contract per slice.** Each roadmap change that introduces or modifies HTTP endpoints gets its own contract file.

2. **Guardrail-first design.** Before defining response shapes, identify what data MUST be excluded per PRD guardrails. Design the contract so guarded data is structurally absent (not just "hidden by convention").

3. **Consistent patterns.** Reuse response/error shapes from existing contracts. Check `context/changes/*/contract.md` for established conventions.

4. **Type-safe by default.** Every field has an explicit type. Use TypeScript-compatible type names (`string`, `number`, `boolean`, `string[]`, `object`). Nullable fields are marked explicitly.

5. **Endpoint naming:**
   - REST conventions: nouns for resources, verbs only when an action doesn't map to CRUD.
   - Base path: `/api/` prefix.
   - Feature grouping: `/api/auth/`, `/api/employees/`, `/api/swipe/`, `/api/matches/`.

6. **Error model consistency.** All error responses use a uniform envelope:
   ```json
   {
     "error": "HUMAN_READABLE_CODE",
     "message": "Descriptive message",
     "details": ["optional", "array", "of", "field-level", "errors"]
   }
   ```

7. **Ask for decisions.** If endpoint design has multiple valid approaches (e.g., "single match endpoint vs. separate like+match-check?" or "paginated vs. full list?"), ask the user with options and recommendations.

8. **Auth documentation.** For each endpoint, explicitly state whether authentication is required. If a slice introduces auth (like F-02), define the token format/header convention that all subsequent contracts will reference.

9. **No implementation details.** The contract describes the HTTP interface, not internal service logic. No mentions of database queries, caching strategies, or Spring annotations — those belong in the plan.

10. **Frontend consumption hints.** Include notes in "Frontend Client Expectations" that help the `src/api/` module author understand patterns (polling vs. push, pagination cursors, etc.).

## Example Invocation

```
/deloitter-contract auth-login-gate
```

Produces `context/changes/auth-login-gate/contract.md` with:
- POST /api/auth/login (credentials → token)
- POST /api/auth/logout (invalidate session)
- GET /api/auth/me (current user info)
- Error responses for invalid credentials, expired token, etc.

## Failure Modes

| Situation | Action |
|-----------|--------|
| Plan doesn't exist for the change-id | Warn user; suggest running `/deloitter-plan` first |
| Slice has no HTTP endpoints (e.g., pure infra) | Inform user that no contract is needed; skip |
| Guardrail conflict detected in endpoint design | STOP, flag to user, propose safe alternative |
| Path collision with existing contract | Warn user, suggest resolution |
